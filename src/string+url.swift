//
//  string+url.swift
//  twohundred
//
//  Created by Johannes Schriewer on 24/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin

/// URL encoding and decoding support
public extension String {

    /// URL-encode string
    ///
    /// - returns: URL-Encoded version of the string
    public func urlEncodedString() -> String {
        var result = ""
        var gen = self.unicodeScalars.generate()
        
        while let c = gen.next() {
            switch c {
            case " ": // Space
                result.appendContentsOf("%20")
            case "!": // !
                result.appendContentsOf("%21")
            case "\"": // "
                result.appendContentsOf("%22")
            case "#": // #
                result.appendContentsOf("%23")
            case "$": // $
                result.appendContentsOf("%24")
            case "%": // %
                result.appendContentsOf("%25")
            case "&": // &
                result.appendContentsOf("%26")
            case "'": // '
                result.appendContentsOf("%27")
            case "(": // (
                result.appendContentsOf("%28")
            case ")": // )
                result.appendContentsOf("%29")
            case "*": // *
                result.appendContentsOf("%2A")
            case "+": // +
                result.appendContentsOf("%2B")
            case ",": // ,
                result.appendContentsOf("%2C")
            case "/": // /
                result.appendContentsOf("%2F")
            case ":": // :
                result.appendContentsOf("%3A")
            case ";": // ;
                result.appendContentsOf("%3B")
            case "=": // =
                result.appendContentsOf("%3D")
            case "?": // ?
                result.appendContentsOf("%3F")
            case "@": // @
                result.appendContentsOf("%40")
            case "[": // [
                result.appendContentsOf("%5B")
            case "\\": // \
                result.appendContentsOf("%5C")
            case "]": // ]
                result.appendContentsOf("%5D")
            case "{": // {
                result.appendContentsOf("%7B")
            case "|": // |
                result.appendContentsOf("%7C")
            case "}": // }
                result.appendContentsOf("%7D")
            default:
                result.append(c)
            }
        }
        return result
    }
    
    /// URL-decode string
    ///
    /// - returns: Decoded version of the URL-Encoded string
    public func urlDecodedString() -> String {
        var result = ""
        var gen = self.unicodeScalars.generate()
        
        while let c = gen.next() {
            switch c {
            case "%":
                // get 2 chars
                if let c1 = gen.next() {
                    if let c2 = gen.next() {
                        if let c = UInt32("\(c1)\(c2)", radix: 16) {
                            result.append(UnicodeScalar(c))
                        } else {
                            result.appendContentsOf("%\(c1)\(c2)")
                        }
                    }
                }
            default:
                result.append(c)
            }
        }

        return result
    }
}