//
//  adler32.swift
//  twohundred
//
//  Created by Johannes Schriewer on 22/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin

/// Adler32 checksumming
public class Adler32 {
    
    private var s1: UInt32 = 1
    private var s2: UInt32 = 0
    private var counter: Int = 0
    
    /// Add data to checksum
    /// 
    /// - parameter data: data to add to the checksum
    public func addData(data: [UInt8]) {
        for c in data {
            if self.counter == 5552 {
                self.counter = 0
                s1 = s1 % 65521
                s2 = s2 % 65521
            }
            s1 = (s1 + UInt32(c))
            s2 = (s2 + s1)
            self.counter++
        }
    }
    
    /// Get CRC of current state
    ///
    /// - returns: 32 Bits of CRC (current state)
    public var crc: UInt32 {
        return (self.s2 << 16) | self.s1
    }
    
    /// Calculate Adler32 CRC of String
    ///
    /// - parameter string: the string to calculate the CRC for
    /// - returns: 32 Bit CRC sum
    public class func crc(string string: String) -> UInt32 {
        let data = [UInt8](string.utf8)
        return self.crc(data: data)
    }
    
    /// Calculate Adler32 CRC of Data
    ///
    /// - parameter data: data to calcuclate the CRC for
    /// - returns: 32 Bit CRC sum
    public class func crc(data data: [UInt8]) -> UInt32 {
        let instance = Adler32()
        instance.addData(data)
        return instance.crc
    }

}

/// Adler32 CRC extension for String
public extension String {
    
    /// Calculate Adler32 CRC for string
    ///
    /// - returns: 32 Bit CRC sum
    public func adler32() -> UInt32 {
        return Adler32.crc(string: self)
    }
}
