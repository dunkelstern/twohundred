//
//  date.swift
//  twohundred
//
//  Created by Johannes Schriewer on 26/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/// Simple Date struct, stores only UTC
public struct Date {
    
    /// Epoch timestamp (seconds since 1970-01-01)
    public let timestamp: Int
    
    /// Simple initializer
    ///
    /// - parameter timestamp: Epoch timestamp (seconds since 1970-01-01)
    public init(timestamp: Int) {
        self.timestamp = timestamp
    }
    
    /// Initialize with ISO-8601 date string
    ///
    /// multiple variants for defining time zone are recognized
    ///
    /// - parameter isoDateString: date string to parse
    /// - returns: nil if string was not parseable
    public init?(isoDateString: String) {
        var time = tm()
        if strptime(isoDateString, "%FT%T%z", &time) == nil {
            if strptime(isoDateString, "%FT%T%Z", &time) == nil {
                if strptime(isoDateString, "%FT%TZ", &time) == nil {
                    if strptime(isoDateString, "%FT%T", &time) == nil {
                        return nil
                    }
                }
            }
        }
        self.timestamp = timegm(&time)
    }
    
    /// Initialize with RFC-822 date string
    ///
    /// multiple variants for defining the time zone are recognized
    ///
    /// - parameter rfc822DateString: date string to parse
    /// - returns: nil if string was not parseable
    public init?(rfc822DateString: String) {
        var time = tm()
        if strptime(rfc822DateString, "%a, %d %b %Y %H:%M:%S %z", &time) == nil {
            if strptime(rfc822DateString, "%a, %d %b %Y %H:%M:%S", &time) == nil {
                return nil
            }
        }
        self.timestamp = mktime(&time)
    }
    
    /// Return a RFC-822 date string
    public var rfc822DateString: String? {
        var output = [Int8](count: 40, repeatedValue: 0)
        var tt = time_t(self.timestamp)
        let t = gmtime(&tt)
        let len = strftime(&output, 40, "%a, %d %b %Y %H:%M:%S +0000", t)
        if len > 0 {
            return String(CString: output, encoding: NSUTF8StringEncoding)
        }
        return nil
    }
    
    
    /// Return a ISO-8601 date string
    public var isoDateString: String? {
        var output = [Int8](count: 40, repeatedValue: 0)
        var tt = time_t(self.timestamp)
        let t = gmtime(&tt)
        let len = strftime(&output, 40, "%FT%TZ", t)
        if len > 0 {
            return String(CString: output, encoding: NSUTF8StringEncoding)
        }
        return nil
    }
}