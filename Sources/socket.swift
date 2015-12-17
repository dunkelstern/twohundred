//
//  socket.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

// TODO: Track idle state of sockets
// TODO: Clean up idle sockets after timeout

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public typealias ReceiveCallback = ((socket: Socket, char: UInt8, connectionID: UUID4, remote: IPAddress?) -> Bool)
public typealias SendCallback = ((data: SocketData, connectionID: UUID4) -> Void)

public class Socket {
    var sock: Int32 = -1
    var workerQueue: dispatch_queue_t?
    var workerSource: dispatch_source_t?
    
    var openConnections = [ConnectionDescriptor]()
    
    var receiveCallback: ReceiveCallback?
    
    public init?(listen addr: IPAddress, port: UInt16, receiveCallback:ReceiveCallback) {
        // setup worker queue
        self.workerQueue = dispatch_queue_create("de.dunkelstern.socketlistener", DISPATCH_QUEUE_CONCURRENT)
        
        // setup ip address query
        var hints = addrinfo()
        var address: String? = nil
        switch addr {
        case .IPv4:
            hints.ai_family = AF_INET
            address = addr.description
        case .IPv6:
            hints.ai_family = AF_INET6
            address = addr.description
        case .Wildcard:
            hints.ai_family = AF_UNSPEC
            hints.ai_flags = AI_PASSIVE
        }
        hints.ai_socktype = SOCK_STREAM
        
        // execute query
        var addrInfo = UnsafeMutablePointer<addrinfo>()
        var result: Int32
        if address == nil {
            result = getaddrinfo(nil, "\(port)", &hints, &addrInfo)
        } else {
            result = getaddrinfo(address!, "\(port)", &hints, &addrInfo)
        }
        if result != 0 {
            Log.fatal("Socket listen(): getaddrinfo error: \(gai_strerror(result))")
            return nil
        }
        
        var info = addrInfo.memory
        while true {
            if info.ai_next == nil || info.ai_family == AF_INET6 {
                break
            }
            info = info.ai_next.memory
        }
        
        // create socket
        self.sock = socket(info.ai_family, info.ai_socktype, info.ai_protocol)
        if self.sock < 0 {
            Log.fatal("Socket listen(): socket creation failed: \(strerror(errno))")
            return nil
        }
        
        // allow reuse
        var yes:Int32 = 1
        setsockopt(self.sock, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(sizeof(Int32)))
        
        // bind to port
        result = bind(self.sock, info.ai_addr, info.ai_addrlen)
        if result < 0 {
            Log.fatal("Socket listen(): bind failed: \(strerror(errno))")
        }
        
        // free query result
        freeaddrinfo(addrInfo)
        
        // start listening
        result = listen(self.sock, 20)
        if result < 0 {
            Log.fatal("Socket listen(): listening failed: \(strerror(errno))")
            close(self.sock)
            return nil
        }
        
        self.receiveCallback = receiveCallback
        
        // dispatch accept calls
        self.workerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(self.sock), 0, self.workerQueue!)
        dispatch_source_set_event_handler(self.workerSource!) {
            var remoteAddr = sockaddr_storage()
            var len = socklen_t(sizeof(sockaddr_storage))
            let sockFD = withUnsafeMutablePointer(&remoteAddr) { remoteAddrPtr in
                return accept(self.sock, UnsafeMutablePointer(remoteAddrPtr), &len)
            }
            if sockFD >= 0 {
                // yay we have a socket, create dispatch source for reading
                let ip = IPAddress(fromString: remoteAddr.description)
                self.handleConnection(sockFD, remote: ip)
            }
        }
        dispatch_resume(self.workerSource!)
    }
    
    public convenience init?(connect: IPAddress, port: UInt16, receiveCallback:ReceiveCallback) {
        self.init(connect: connect.description, port: port, receiveCallback: receiveCallback)
    }
    
    public init?(connect addr: String, port: UInt16, receiveCallback:ReceiveCallback) {
        self.receiveCallback = receiveCallback

        // setup query
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        
        // execute query
        var addrInfo = UnsafeMutablePointer<addrinfo>()
        let result = getaddrinfo(addr, "\(port)", &hints, &addrInfo)
        
        if result != 0 {
            Log.error("Socket connect(): getaddrinfo error: \(gai_strerror(result))")
            return nil
        }
        
        // create socket
        self.sock = socket(addrInfo.memory.ai_family, addrInfo.memory.ai_socktype, addrInfo.memory.ai_protocol)
        if self.sock < 0 {
            Log.error("Socket connect(): socket creation failed: \(strerror(errno))")
            return nil
        }

        // finally connect
        if connect(self.sock, addrInfo.memory.ai_addr, addrInfo.memory.ai_addrlen) < 0 {
            Log.error("Socket connect(): connection failed: \(strerror(errno))")
            return nil
        }
        
        var remoteAddr = sockaddr_storage()
        var len = socklen_t(sizeof(sockaddr_storage))
        withUnsafeMutablePointer(&remoteAddr) { remoteAddrPtr in
            getpeername(self.sock, UnsafeMutablePointer(remoteAddrPtr), &len)
        }
        let ip = IPAddress(fromString: remoteAddr.description)

        self.handleConnection(self.sock, remote: ip)
        
        // free query result
        freeaddrinfo(addrInfo)
    }
}

// MARK: - Receiving data
extension Socket {

    internal func handleConnection(fd: Int32, remote: IPAddress?) {
        let readSrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(fd), 0, self.workerQueue)
        let desc = ConnectionDescriptor(read: readSrc, remote: remote, fd: fd)

        dispatch_source_set_event_handler(desc.readSource) {
            var c: UInt8 = 0

            // read a byte
            if read(desc.fd, &c, 1) != 1 {
                if errno == EAGAIN || errno == EINTR {
                    // if we got interrupted just try again
                    return
                }
            }
            
            if !self.receiveCallback!(socket: self, char: c, connectionID: desc.id, remote: desc.remote) {
                // if callback returns false, do not read more data
                dispatch_source_cancel(desc.readSource)
            }
        }
        
        dispatch_source_set_cancel_handler(desc.readSource) {
            // if no one uses the socket anymore close it and remove the open connection from the list
            desc.socketRetainCount--
            if desc.socketRetainCount == 0 {
                close(desc.fd)
                self.openConnections.removeAtIndex(self.openConnections.indexOf({ cDesc -> Bool in
                    return cDesc.id == desc.id
                })!)
            }
        }
        
        self.openConnections.append(desc)
        dispatch_resume(desc.readSource)
    }
}

// MARK: - Sending data
extension Socket {
    public func send(data: SocketData, connectionID: UUID4, successCallback:SendCallback?) -> Bool {
        var found: ConnectionDescriptor? = nil
        for conn in self.openConnections {
            if conn.id == connectionID {
                found = conn
                break
            }
        }
        guard let connection = found else {
            return false
        }

        connection.queueData(data, callback: successCallback)
        
        if connection.writeSource == nil {
            // start write source
            connection.socketRetainCount++
            connection.writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, UInt(connection.fd), 0, self.workerQueue)
            dispatch_source_set_event_handler(connection.writeSource!) {
                
                if let queueItem = connection.sendQueue.first {
                    let estimated = dispatch_source_get_data(connection.writeSource!)
                    var dataToSend = queueItem.fetchData(size_t(estimated))
                
                    while true {
                        if write(connection.fd, &dataToSend, dataToSend.count) != dataToSend.count {
                            if errno == EAGAIN || errno == EINTR {
                                // if we got interrupted just try again
                                continue
                            }
                            break
                        }
                        break
                    }
                    
                    // when finished, call success callback and pop the data item from the queue
                    if queueItem.isFinished() {
                        if let callback = queueItem.callback {
                            callback(data: queueItem.data, connectionID: connection.id)
                        }
                        connection.sendQueue.removeFirst()
                    }
                }
                
                // cancel the write source when there are not items in the send queue anymore
                if connection.sendQueue.count == 0 {
                    dispatch_source_cancel(connection.writeSource!)
                    connection.writeSource = nil
                }
            }

            dispatch_source_set_cancel_handler(connection.writeSource!) {
                // if no one uses the socket anymore close it and remove the open connection from the list
                connection.socketRetainCount--
                if connection.socketRetainCount == 0 {
                    close(connection.fd)
                    self.openConnections.removeAtIndex(self.openConnections.indexOf({ cDesc -> Bool in
                        return cDesc.id == connection.id
                    })!)
                }
            }

            dispatch_resume(connection.writeSource!)
        }
        
        return true
    }
}

