//
//  connection_descriptor.swift
//  twohundred
//
//  Created by Johannes Schriewer on 22/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

class ConnectionDescriptor {
    var id: UUID4
    var fd: Int32
    var readSource: dispatch_source_t
    var writeSource: dispatch_source_t?
    var remote: IPAddress?
    
    var socketRetainCount: Int

    class QueuedData {
        var data: SocketData
        var callback: SendCallback?
        var position: size_t = 0
        var fd: Int32 = -1
        
        init?(data: SocketData, callback: SendCallback?) {
            self.data = data
            self.callback = callback
            
            if case .File(let filename) = self.data {
                self.fd = open(filename, O_RDONLY)
                if self.fd < 0 {
                    Log.error("QueuedData: open failed: \(strerror(errno))")
                    return nil
                }
            }
        }
        
        func isFinished() -> Bool {
            switch self.data {
            case .Data(let data):
                return data.count == self.position
            case .StringData(let string):
                return string.utf8.count == self.position
            case .File:
                return self.fd == -1
            }
        }
        
        func fetchData(length: size_t) -> [UInt8] {
            switch self.data {
                
            case .Data(let data):
                // slice data array
                let result = [UInt8](data.suffixFrom(self.position).prefix(length))
                self.position += result.count
                return result
                
            case .StringData(let string):
                // slice string
                let startPosition = string.utf8.startIndex
                var endPosition:String.UTF8View.Index
                if self.position + length > string.utf8.count {
                    endPosition = string.utf8.endIndex
                } else {
                    endPosition = startPosition.advancedBy(self.position + length)
                }
                let array = [UInt8](string.utf8[startPosition..<endPosition])
                self.position += array.count
                return array
                
            case .File:
                // try to read bytes
                var buffer = Array<UInt8>(count: length, repeatedValue: 0)
                while true {
                    let result = read(self.fd, &buffer, length)
                    if (result < 0) {
                        if errno == EINTR || errno == EAGAIN {
                            // transient failure, try again
                            continue
                        }
                        
                        Log.error("QueuedData fetchData() failed: \(strerror(errno))")
                        return []
                    } else {
                        self.position += result
                        if result == 0 {
                            close(self.fd)
                            self.fd = -1
                        }
                    }
                    return [UInt8](buffer.prefix(result))
                }
            }
        }
    }

    var sendQueue = [QueuedData]()
    
    init(read: dispatch_source_t, remote: IPAddress?, fd: Int32) {
        self.id = UUID4()
        self.fd = fd
        self.readSource = read
        self.remote = remote
        self.socketRetainCount = 1
    }
    
    func queueData(data: SocketData, callback: SendCallback?) -> Bool {
        if let data = QueuedData(data: data, callback: callback) {
            self.sendQueue.append(data)
            return true
        }
        return false
    }
}