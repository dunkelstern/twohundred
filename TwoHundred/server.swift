//
//  server.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import UnchainedIPAddress
import UnchainedLogger
import UnchainedSocket
import UnchainedString

/// HTTP Server baseclass, subclass to get useful behaviour
public class TwoHundredServer {
    typealias ResponseHandlerBlock = @convention(block) (connection: UnsafeMutablePointer<Connection>, data: UnsafePointer<CChar>, size: Int) -> Bool
    private var serverResponseHandlerBlock: ResponseHandlerBlock?

    private var serverHandle: COpaquePointer = nil
    private var requestHeaderData = [Int32:String]()
    private var requestHeader     = [Int32:RequestHeader]()
    private var requestBody       = [Int32:[UInt8]]()
    
    /// Listening address
    public let listeningAddress: IPAddress
    
    /// Listening port
    public let listeningPort: UInt16
    
    // TODO: SSL/TLS config
    // TODO: receive and send buffer sizes
    // TODO: temporary file storage for big transfers
    
    /// initialize with minimum settings needed
    ///
    /// - Parameter listenAddress: address to listen on, use 0.0.0.0 for all interfaces
    /// - Parameter port: the port to listen on, must be root to listen to ports below 1024
    public init(listenAddress: IPAddress, port: UInt16) {
        self.listeningAddress = listenAddress
        self.listeningPort = port
    }

    /// initialize for localhost
    ///
    /// - Parameter listenPort: port to listen on, must be root to listen to ports below 1024
    public convenience init(listenPort: UInt16) {
        self.init(listenAddress: .Wildcard, port:listenPort)
    }
    
    /// simplest possible initializer (localhost on port 8000)
    public convenience init() {
        self.init(listenAddress: .Wildcard, port: 8000)
    }
   

    /// run the server
    public func start() {
        self.serverHandle = server_init(self.listeningAddress.description, "\(self.listeningPort)", false, 10)
		if serverHandle == nil {
			Log.fatal("Could not initialize server!")
			abort()
		}

		self.serverResponseHandlerBlock = { (connection: UnsafeMutablePointer<Connection>, data: UnsafePointer<CChar>, size: Int) -> Bool in
			let connectionID = connection.memory.id
			let remote = IPAddress(fromString: String.fromCString(connection.memory.remoteIP)!)

			let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(data), count: size)
			for char in buffer {
				if self.requestHeaderData[connectionID] == nil {
					self.requestHeaderData[connectionID] = ""
				}
				if self.requestBody[connectionID] == nil {
					// we're in header phase, append data to header
					self.requestHeaderData[connectionID]!.append(UnicodeScalar(char))
					if self.requestHeaderData[connectionID]!.isSuffixed("\r\n\r\n") {
						if let header = RequestHeader(data: self.requestHeaderData[connectionID]!) {
							self.requestHeader[connectionID] = header
							self.requestHeaderData[connectionID] = ""
							
							if let hdr = self.requestHeader[connectionID]!["Content-Length"] {
								if let contentLength = Int(hdr) where contentLength == 0 {
									self.prepareRequest(connection, remote: remote)
									return false
								} else {
									self.requestBody[connectionID] = [UInt8]()
								}
							} else {
								self.prepareRequest(connection, remote: remote)
								return false
							}
						} else {
							return false
						}
					}
				} else {
					// ok body phase, append to body
					guard let hdr = self.requestHeader[connectionID]!["Content-Length"],
						  let contentLength = Int(hdr) else {
						return false
					}
					self.requestBody[connectionID]!.append(char)

					if (self.requestBody[connectionID]!.count == contentLength) {
						self.prepareRequest(connection, remote: remote)
						return false
					}
				}
			}
			return true
		}

		server_start(self.serverHandle, { (connection, instance, data, size) -> Bool in
			let handler = unsafeBitCast(instance, ResponseHandlerBlock.self)
			return handler(connection: connection, data: data, size: size)
		}, unsafeBitCast(self.serverResponseHandlerBlock, UnsafeMutablePointer<Void>.self), 30)
	}

	public func stop() {
		server_stop(self.serverHandle)
	}

    /// Override this function in your own TwoHundred subclass to handle requests
    ///
    /// - parameter request: the request to handle
    /// - returns: HTTPResponse to send
    public func handleRequest(request: HTTPRequest) -> HTTPResponseBase {
        Log.debug("Request from \(request.remoteIP): \(request.header.method) \(request.header.url)")
        return HTTPResponseBase()
    }
    
    // MARK: - Private
    
    private func prepareRequest(connection: UnsafeMutablePointer<Connection>, remote: IPAddress?) {
		let connectionID = connection.memory.id
        let body = self.requestBody[connectionID]
        let header = self.requestHeader[connectionID]!

        let request = HTTPRequest(remoteIP: remote, header: header, data: body)
        let response = self.handleRequest(request)
		let data = response.makeSocketData()
		if case .StringData(let data) = data {
			server_send_data(connection, data, data.utf8.count)
		}

        //self.socket!.send(response.makeSocketData(), connectionID: connectionID, successCallback: nil)
        
        if header.method != .HEAD {
            for result in response.body {
				switch result {
				case .StringData(let data):
					server_send_data(connection, data, data.utf8.count)
				case .Data(let data):
					server_send_data(connection, UnsafePointer<CChar>(data), data.count)
				case .File(let filename):
					server_send_file(connection, filename)
				}
                //self.socket!.send(result, connectionID: connectionID, successCallback: nil)
            }
        }
        
        self.requestBody.removeValueForKey(connectionID)
        self.requestHeader.removeValueForKey(connectionID)
        self.requestHeaderData.removeValueForKey(connectionID)
    }
}
