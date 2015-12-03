//
//  ipaddress.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum IPAddress {
    case IPv4(_: UInt8, _: UInt8, _: UInt8, _: UInt8)
    case IPv6(_: UInt16, _: UInt16, _: UInt16, _: UInt16, _: UInt16, _: UInt16, _: UInt16, _: UInt16)
    case Wildcard
    
    public init?(fromString inputString: String) {
        var fromString = inputString
        if fromString.hasPrefix("::ffff:") {
            // special case, this is a IPv4 address returned from the IPv6 stack
            fromString = inputString.substringFromIndex(inputString.startIndex.advancedBy(7)).stringByReplacingOccurrencesOfString(":", withString: ".")
        }

        if fromString.containsString(":") {
            // IPv6
            var components: [String]
            if fromString.hasPrefix("::") {
                components = fromString.substringFromIndex(fromString.startIndex.advancedBy(1)).componentsSeparatedByString(":")
            } else {
                components = fromString.componentsSeparatedByString(":")
                if components.count > 8 || components.count < 1 {
                    return nil
                }
            }

            var segments = [UInt16]()
            var filled = false
            for component in components {
                if component.characters.count == 0 && !filled {
                    filled = true
                    for _ in 0...(8 - components.count) {
                        segments.append(0)
                    }
                    continue
                }
                if let segment = UInt32(component, radix: 16) {
                    if segment > 65535 {
                        return nil
                    }
                    segments.append(UInt16(segment))
                } else {
                    return nil
                }
            }
            self = .IPv6(segments[0], segments[1], segments[2], segments[3], segments[4], segments[5], segments[6], segments[7])
        } else {
            // IPv4
            let components = fromString.componentsSeparatedByString(".")
            if components.count != 4 {
                return nil
            }
            
            var segments = [UInt8]()
            for component in components {
                if let segment = UInt16(component, radix: 10) {
                    if segment > 255 {
                        return nil
                    }
                    segments.append(UInt8(segment))
                } else {
                    return nil
                }
            }
            self = .IPv4(segments[0], segments[1], segments[2], segments[3])
        }
    }
    
    public func sin_addr() -> in_addr? {
        switch self {
        case .IPv4:
            var sa = in_addr()
            inet_pton(AF_INET, self.description, &sa)
            return sa
        case .Wildcard:
            var sa = in_addr()
            inet_pton(AF_INET, "0.0.0.0", &sa)
            return sa
        default:
            return nil
        }
    }

    public func sin6_addr() -> in6_addr? {
        switch self {
        case .IPv6:
            var sa = in6_addr()
            inet_pton(AF_INET6, self.description, &sa)
            return sa
        case .Wildcard:
            var sa = in6_addr()
            inet_pton(AF_INET6, "::", &sa)
            return sa
        default:
            return nil
        }
    }
}

extension IPAddress: CustomStringConvertible {
    public var description: String {
        switch(self) {
        case .IPv4(let s1, let s2, let s3, let s4):
            return "\(s1).\(s2).\(s3).\(s4)"
        case .IPv6(let s1, let s2, let s3, let s4, let s5, let s6, let s7, let s8):
            let segments = [s8, s7, s6, s5, s4, s3, s2, s1]
            var result = ""
            var gapStarted = false, gapEnded = false
            for segment in segments {
                if (segment == 0) && (!gapEnded) {
                    if (!gapStarted) {
                        gapStarted = true
                        result = ":" + result
                    }
                    continue
                }
                if gapStarted && !gapEnded {
                    gapEnded = true
                }
                result = ":" + segment.hexString(padded: false) + result
            }
            if !result.hasPrefix("::") {
                result = result.substringFromIndex(result.startIndex.advancedBy(1))
            }
            return result
        case .Wildcard:
            return "*"
        }
    }
}

extension in_addr: CustomStringConvertible {
    public var description: String {
        var result = [CChar](count: Int(INET_ADDRSTRLEN), repeatedValue: 0)
        var copy = self
        inet_ntop(AF_INET, &copy, &result, socklen_t(INET_ADDRSTRLEN))
        if let string = String(CString: result, encoding: NSUTF8StringEncoding) {
            return string
        }
        return "<in_addr: invalid>"
    }
}

extension in6_addr: CustomStringConvertible {
    public var description: String {
        var result = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
        var copy = self
        inet_ntop(AF_INET6, &copy, &result, socklen_t(INET6_ADDRSTRLEN))
        if let string = String(CString: result, encoding: NSUTF8StringEncoding) {
            return string
        }
        return "<in6_addr: invalid>"
    }
}

extension sockaddr_storage: CustomStringConvertible {
    public var description: String {
        var copy = self
        let result:String = withUnsafePointer(&copy) { ptr in
            var host = [CChar](count: 1000, repeatedValue: 0)
            if getnameinfo(UnsafeMutablePointer(ptr), socklen_t(copy.ss_len), &host, 1000, nil, 0, NI_NUMERICHOST) == 0 {
                return String(CString: host, encoding: NSUTF8StringEncoding)!
            } else {
                return "<sockaddr: invalid>"
            }
        }
        return result
    }
}