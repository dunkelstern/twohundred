//
//  SocketData.swift
//  twohundred
//
//  Created by Johannes Schriewer on 22/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//


public enum SocketData: Equatable {
    /// encapsulates a string
    case StringData(_: String)

    /// encapsulates arbitrary binary data
    case Data(_: [UInt8])
    
    /// encapsulates a file to save RAM
    case File(_: String)
    
    /// Calculate byte size of this part
    ///
    /// - returns: byte size or 0 if unknown
    func calculateSize() -> size_t {
        switch self {
        case .StringData(let string):
            return string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        case .Data(let data):
            return data.count
        case .File(let filename):
            var s = stat()
            if stat(filename, &s) != 0 {
                return 0
            } else {
                return size_t(s.st_size)
            }
        }
    }
}

public func ==(lhs: SocketData, rhs: SocketData) -> Bool {
    return (lhs == rhs) && (lhs.hashValue == rhs.hashValue)
}

/// Hashable extension for SocketData
extension SocketData: Hashable {
    
    /// Calculate reasonable hash value for content
    ///
    /// - returns: hash value
    public var hashValue: Int {
        switch self {
        case .StringData(let string):
            /// string data is simple, it returns hashValue of the string
            return string.hashValue
        case .Data(let data):
            /// binary data is a bit harder, we have to calculate a checksum of the data as a hash
            return Int(Adler32.crc(data: data))
        case .File(let filename):
            /// file data is simple too, it returns hashValue of the filename
            return filename.hashValue
        }
    }

}