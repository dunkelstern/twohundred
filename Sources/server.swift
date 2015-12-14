//
//  server.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

/// HTTP Server baseclass, subclass to get useful behaviour
public class TwoHundredServer {
    private var requestHeaderData = [UUID4:String]()
    private var requestHeader     = [UUID4:RequestHeader]()
    private var requestBody       = [UUID4:[UInt8]]()
    
    private var socket: Socket? = nil
    
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
    
    /// run the server, call `dispatch_main` at end of main() function for it to work
    public func start() {
        self.socket = Socket(listen: self.listeningAddress, port: self.listeningPort) { (socket, char, connectionID, remote) -> Bool in
            if self.requestHeaderData[connectionID] == nil {
                self.requestHeaderData[connectionID] = ""
            }
            if self.requestBody[connectionID] == nil {
                // we're in header phase, append data to header
                self.requestHeaderData[connectionID]!.append(UnicodeScalar(char))
                if self.requestHeaderData[connectionID]!.hasSuffix("\r\n\r\n") {
                    if let header = RequestHeader(data: self.requestHeaderData[connectionID]!) {
                        self.requestHeader[connectionID] = header
                        self.requestHeaderData[connectionID] = ""
                        
                        if let hdr = self.requestHeader[connectionID]!["Content-Length"] {
                            if let contentLength = Int(hdr) where contentLength == 0 {
                                self.prepareRequest(connectionID, remote: remote)
                                return false
                            } else {
                                self.requestBody[connectionID] = [UInt8]()
                            }
                        } else {
                            self.prepareRequest(connectionID, remote: remote)
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
                    self.prepareRequest(connectionID, remote: remote)
                    return false
                }
            }
            return true
        }
    }

    /// Override this function in your own TwoHundred subclass to handle requests
    ///
    /// - parameter request: the request to handle
    /// - returns: HTTPResponse to send
    public func handleRequest(request: HTTPRequest) -> HTTPResponseBase {
        print("Request from \(request.remoteIP): \(request.header.method) \(request.header.url)")
        return HTTPResponseBase()
    }
    
    // MARK: - Private
    
    private func prepareRequest(connectionID: UUID4, remote: IPAddress?) {
        let body = self.requestBody[connectionID]
        let header = self.requestHeader[connectionID]!

        let request = HTTPRequest(remoteIP: remote, header: header, data: body)
        let response = self.handleRequest(request)
        self.socket!.send(response.makeSocketData(), connectionID: connectionID, successCallback: nil)
        
        if header.method != .HEAD {
            for result in response.body {
                self.socket!.send(result, connectionID: connectionID, successCallback: nil)
            }
        }
        
        self.requestBody.removeValueForKey(connectionID)
        self.requestHeader.removeValueForKey(connectionID)
        self.requestHeaderData.removeValueForKey(connectionID)
    }
}