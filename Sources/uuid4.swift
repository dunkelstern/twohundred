//
//  uuid4.swift
//  twohundred
//
//  Created by Johannes Schriewer on 21/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/// UUID (Random class)
public class UUID4: Equatable {
    private var bytes:[UInt8]!
    
    /// Initialize random UUID
    public init() {
        self.bytes = [UInt8](count: 16, repeatedValue: 0)
        for i in 0..<16 {
            self.bytes[i] = UInt8(arc4random_uniform(256))
        }
        self.bytes[6] = self.bytes[6] & 0x0f + 0x40
        self.bytes[8] = self.bytes[8] & 0x3f + 0x80
    }
    
    /// Initialize UUID from bytes
    ///
    /// - parameter bytes: 16 bytes of UUID data
    /// - returns: nil if the bytes are no valid UUID
    public init?(bytes: [UInt8]) {
        guard (bytes.count == 16) &&
              (bytes[6] & 0xf0 == 0x40) &&
              (bytes[8] & 0xc0 == 0x80) else {
            return nil
        }
        self.bytes = bytes
    }
}

/// UUIDs are equal when all bytes are equal
public func ==(lhs: UUID4, rhs: UUID4) -> Bool {
    var same = true
    for i in 0..<16 {
        if lhs.bytes[i] != rhs.bytes[i] {
            same = false
            // do not break here for constant time comparison of UUID
        }
    }
    return same
}

/// Printable UUID
extension UUID4: CustomStringConvertible {
    
    /// "Human readable" version of the UUID
    public var description: String {
        return "\(bytes[0].hexString())\(bytes[1].hexString())\(bytes[2].hexString())\(bytes[3].hexString())-\(bytes[4].hexString())\(bytes[5].hexString())-\(bytes[6].hexString())\(bytes[7].hexString())-\(bytes[8].hexString())\(bytes[9].hexString())-\(bytes[10].hexString())\(bytes[11].hexString())\(bytes[12].hexString())\(bytes[13].hexString())\(bytes[14].hexString())\(bytes[15].hexString())".uppercaseString
    }
}

/// Hashing extension for UUID
extension UUID4: Hashable {
    /// calculate hash value from UUID
    public var hashValue: Int {
        var hash: Int = 0
        hash += Int(self.bytes[0] ^ self.bytes[8])
        hash += Int(self.bytes[1] ^ self.bytes[9])  >> 8
        hash += Int(self.bytes[2] ^ self.bytes[10]) >> 16
        hash += Int(self.bytes[3] ^ self.bytes[11]) >> 24
        hash += Int(self.bytes[4] ^ self.bytes[12]) >> 32
        hash += Int(self.bytes[5] ^ self.bytes[13]) >> 40
        hash += Int(self.bytes[6] ^ self.bytes[14]) >> 48
        hash += Int(self.bytes[7] ^ self.bytes[15]) >> 56
        
        return hash
    }
}