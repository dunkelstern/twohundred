//
//  header.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

/// HTTP Request header
public class RequestHeader {
    
    /// Defined headers
    public var headers = [String:String]()
    
    /// Request method
    public var method: HTTPMethod = .INVALID
    
    /// HTTP version
    public var version: HTTPVersion = .Invalid
    
    /// Requested url
    public var url: String! = nil
    
    /// Decoded GET parameters
    public var getParameters = [String:String]()
    
    /// Decoded fragment (should probably not be in a request)
    public var fragment: String = ""
    
    /// Initialize with data
    ///
    /// - parameter data: HTTP request headers as one long string
    /// - returns: nil if header data could not be parsed
    init?(data: String) {
        if !self.parse(data) {
            return nil
        }
    }

    // MARK: - API
    
    /// RequestHeader is subscriptable
    ///
    /// - parameter index: HTTP header name to query or set or one of `HTTP_METHOD` or `HTTP_VERSION`
    /// - returns: value of corresponding HTTP header, method or version
    public subscript(index: String) -> String? {
        get {
            switch index {
            case "HTTP_METHOD":
                return self.method.rawValue
            case "HTTP_VERSION":
                return self.version.rawValue
            default:
                return self.headers[index]
            }
        }
        
        set(newValue) {
            switch index {
            case "HTTP_METHOD":
                guard let newValue = newValue else {
                    return
                }
                if let method = HTTPMethod(rawValue: newValue) {
                    self.method = method
                } else {
                    self.method = .INVALID
                }
            case "HTTP_VERSION":
                guard let newValue = newValue else {
                    return
                }
                if let version = HTTPVersion(rawValue: newValue) {
                    self.version = version
                } else {
                    self.version = .Invalid
                }
            default:
                self.headers[index] = newValue
            }
        }
    }
    
    // MARK: - Parser
    
    private enum HeaderParserStates {
        case Method
        case BeforeURL
        case URL
        case QueryStringName
        case QueryStringValue
        case Fragment
        case AfterURL
        case Version
        
        case Name
        case BeforeValue
        case Value
        case ErrorState
        
        case FatalErrorState
    }

    private var state: HeaderParserStates = .Method
    private func parse(data: String) -> Bool {
        var generator: String.CharacterView.Generator
        if !data.hasSuffix("\r\n") {
            generator = "\(data)\r\n".characters.generate()
        } else {
            generator = data.characters.generate()
        }

        self.state = .Method

        var currentName: String?
        while true {
            guard let c = generator.next() else {
                break
            }
            switch self.state {
            // first request line
            case .Method:
                guard let method = self.parseMethod(c),
                      let m = HTTPMethod(rawValue: method) else {
                    continue
                }
                self.method = m
            case .BeforeURL:
                self.parseBeforeURL(c)
            case .URL:
                if let url = self.parseURL(c) {
                    self.url = url
                    // the url will be canonized after parsing the complete headers as we need to add the host part
                }
            case .QueryStringName:
                if let name = self.parseQueryStringName(c) {
                    currentName = name.urlDecodedString()
                }
            case .QueryStringValue:
                guard let value = self.parseQueryStringValue(c),
                      let name = currentName else {
                    continue
                }
                self.getParameters[name] = value.urlDecodedString()
                currentName = nil
            case .Fragment:
                if let fragment = self.parseURLFragment(c) {
                    self.fragment = fragment
                }
            case .AfterURL:
                self.parseAfterURL(c)
            case .Version:
                guard let version = self.parseVersion(c),
                      let v = HTTPVersion(rawValue: version) else {
                    continue
                }
                self.version = v
                
            // actual HTTP headers
            case .Name:
                if let name = self.parseName(c) {
                    currentName = name
                }
            case .BeforeValue:
                self.parseBeforeValue(c)
            case .Value:
                guard let value = self.parseValue(c),
                      let name = currentName else {
                    continue
                }
                self.headers[name] = value
                currentName = nil
            case .ErrorState:
                self.parseErrorState(c)
            
            // fatal parsing error
            case .FatalErrorState:
                return false
            }
        }
        
        return true
    }
    
    // MARK: first line
    private var methodTemp: String = ""
    private func parseMethod(c: Character) -> String? {
        switch c {
        case "A"..."Z":
            self.methodTemp.append(c)
        case "a"..."z":
            self.methodTemp.appendContentsOf("\(c)".lowercaseString)
        case " ", "\t":
            self.state = .BeforeURL
            let result = methodTemp
            self.methodTemp = ""
            return result
        default:
            self.state = .FatalErrorState
        }
        return nil
    }

    private func parseBeforeURL(c: Character) {
        switch c {
        case " ", "\t":
            break
        default:
            self.urlTemp.append(c)
            self.state = .URL
        }
    }

    private var urlTemp: String = ""
    private func parseURL(c: Character) -> String? {
        switch c {
        case " ", "\t":
            self.state = .AfterURL
            let result = self.urlTemp
            self.urlTemp = ""
            return result
        case "?":
            self.state = .QueryStringName
            let result = self.urlTemp
            self.urlTemp = ""
            return result
        case "#":
            self.state = .Fragment
            let result = self.urlTemp
            self.urlTemp = ""
            return result
        default:
            // parse error
            self.urlTemp.append(c)
        }
        return nil
    }
    
    private var queryStringNameTemp: String = ""
    private func parseQueryStringName(c: Character) -> String? {
        switch c {
        case " ", "\t":
            self.state = .AfterURL
            let result = self.queryStringNameTemp
            self.queryStringNameTemp = ""
            return result
        case "&":
            self.state = .QueryStringName
            let result = self.queryStringNameTemp
            self.queryStringNameTemp = ""
            return result
        case "=":
            self.state = .QueryStringValue
            let result = self.queryStringNameTemp
            self.queryStringNameTemp = ""
            return result
        case "#":
            self.state = .Fragment
            let result = self.queryStringNameTemp
            self.queryStringNameTemp = ""
            return result
        default:
            // parse error
            self.queryStringNameTemp.append(c)
        }
        return nil
    }
    
    private var fragmentTemp: String = ""
    private func parseURLFragment(c: Character) -> String? {
        switch c {
        case " ", "\t":
            self.state = .AfterURL
            let result = self.fragmentTemp
            self.fragmentTemp = ""
            return result
        default:
            self.fragmentTemp.append(c)
        }
        return nil
    }

    private var queryStringValueTemp: String = ""
    private func parseQueryStringValue(c: Character) -> String? {
        switch c {
        case " ", "\t":
            self.state = .AfterURL
            let result = self.queryStringValueTemp
            self.queryStringValueTemp = ""
            return result
        case "&":
            self.state = .QueryStringName
            let result = self.queryStringValueTemp
            self.queryStringValueTemp = ""
            return result
        case "#":
            self.state = .Fragment
            let result = self.queryStringValueTemp
            self.queryStringValueTemp = ""
            return result
        default:
            // parse error
            self.queryStringValueTemp.append(c)
        }
        return nil
    }

    private func parseAfterURL(c: Character) {
        switch c {
        case " ", "\t":
            break
        case "H":
            self.versionTemp.append(c)
            self.state = .Version
        default:
            self.state = .FatalErrorState
        }
    }
    
    private var versionTemp: String = ""
    private func parseVersion(c: Character) -> String? {
        switch c {
        case "H", "T", "P", "/", "0"..."9", ".":
            self.versionTemp.append(c)
        case "\r\n", "\n":
            self.state = .Name
            let result = self.versionTemp
            self.versionTemp = ""
            return result
        default:
            self.state = .FatalErrorState
        }
        return nil
    }
    
    // MARK: HTTP Headers
    
    var nameTemp: String = ""
    private func parseName(c: Character) -> String? {
        switch c {
        case "A"..."Z", "a"..."z", "0"..."9", "-", "_":
            self.nameTemp.append(c)
        case ":":
            self.state = .BeforeValue
            let result = self.nameTemp
            self.nameTemp = ""
            return result
        default:
            self.nameTemp = ""
            self.state = .ErrorState
        }
        return nil
    }
    
    private func parseBeforeValue(c: Character) {
        switch c {
        case " ", "\t":
            break
        default:
            valueTemp.append(c)
            self.state = .Value
        }
    }
    
    var valueTemp: String = ""
    private func parseValue(c: Character) -> String? {
        switch c {
        case "\r\n", "\n":
            self.state = .Name
            let result = self.valueTemp
            self.valueTemp = ""
            return result
        default:
            self.valueTemp.append(c)
        }
        return nil
    }
    
    private func parseErrorState(c: Character) {
        switch c {
        case "\r\n", "\n":
            self.state = .Name
        default:
            break
        }
    }
}