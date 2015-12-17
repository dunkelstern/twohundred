//
//  cookie.swift
//  twohundred
//
//  Created by Johannes Schriewer on 09/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

public struct Cookie {
    public var name: String
    public var value: String
    public var domain: String
    public var path: String
    public var expires: Date?
    public var secure: Bool
    public var httpOnly: Bool
    
    /// Create a Cookie
    ///
    /// - parameter name: name of the cookie
    /// - parameter value: value of the cookie
    /// - parameter domain: cookie domain
    /// - parameter path: path, defaults to /
    /// - parameter expires: expiry date or nil for permanent cookies
    /// - parameter secure: only send cookie over HTTPS, defaults to secure cookies
    /// - parameter httpOnly: only use cookie for HTTP/S queries, will be unaccessible by javascript when set to true
    public init(name: String, value: String, domain: String, path: String = "/", expires: Date? = nil, secure: Bool = true, httpOnly: Bool = true) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.expires = expires
        self.secure = secure
        self.httpOnly = httpOnly
    }
    
    /// Parse a Cookie from a HTTP header value
    public init(headerValue: String) {
        self.httpOnly = false
        self.secure = false
        self.path = "/"
        self.domain = ""
        self.name = ""
        self.value = ""
        
        // split components
        let components = headerValue.componentsSeparatedByString(";")
        for c in components {
            
            // if component contains a equals sign split
            if c.containsString("=") {
                let parts = c.componentsSeparatedByString("=")
                switch parts[0].lowercaseString.stringByTrimmingWhitespace() {
                case "domain":
                    self.domain = parts[1].stringByTrimmingWhitespace()
                case "path":
                    self.path = parts[1].stringByTrimmingWhitespace()
                case "expires":
                    self.expires = Date(rfc822DateString: parts[1].stringByTrimmingWhitespace())
                default:
                    self.name = parts[0].stringByTrimmingWhitespace()
                    self.value = parts[1].stringByTrimmingWhitespace()
                }
            } else {
                // is a flag
                switch c.lowercaseString.stringByTrimmingWhitespace() {
                case "secure":
                    self.secure = true
                case "httponly":
                    self.httpOnly = true
                default:
                    Log.warn("Cookie: unkown flag \(c)")
                }
            }
        }
    }

    /// HTTP header string
    public var headerString: String {
        var value = "\(self.name)=\(self.value); Domain=\(self.domain); Path=\(self.path)"
        if let expires = self.expires {
            value.appendContentsOf("; Expires=\(expires.rfc822DateString)")
        }
        if self.secure {
            value.appendContentsOf("; Secure")
        }
        if self.httpOnly {
            value.appendContentsOf("; HttpOnly")
        }

        return value
    }
}