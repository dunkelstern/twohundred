//
//  http_defs.swift
//  twohundred
//
//  Created by Johannes Schriewer on 25/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin

/// Valid HTTP methods
public enum HTTPMethod: String {
    case GET = "GET"
    case PUT = "PUT"
    case POST = "POST"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case OPTIONS = "OPTIONS"
    case HEAD = "HEAD"
    case TRACE = "TRACE"
    
    case INVALID
}

/// Valid HTTP versions
public enum HTTPVersion: String {
    case v10 = "HTTP/1.0"
    case v11 = "HTTP/1.1"
    case v2 = "HTTP/2"
    
    case Invalid
}

/// Available HTTP status codes
public enum HTTPStatusCode: String {
    // Success
    case Ok = "200 ok"
    case Created = "201 created"
    case Accepted = "202 accepted"
    case NonAuthoritative = "203 non-authoritative information"
    case NoContent = "204 no content"
    case ResetContent = "205 reset content"
    case PartialContent = "206 partial content"
    
    // Redirect
    case MultipleChoices = "300 multiple choices"
    case MovedPermanently = "301 moved permanently"
    case Found = "302 found"
    case SeeOther = "303 see other"
    case NotModified = "304 not modified"
    case TemporaryRedirect = "307 temporary redirect"
    case PermanentRedirect = "308 permanent redirect"
    
    // Error
    case BadRequest = "400 bad request"
    case Unauthorized = "401 unauthorized"
    case Forbidden = "403 forbidden"
    case NotFound = "404 not found"
    case MethodNotAllowed = "405 method not allowed"
    case NotAcceptable = "406 not acceptable"
    case RequestTimeout = "408 request timeout"
    case Conflict = "409 conflict"
    case Gone = "410 gone"
    case LengthRequired = "411 length required"
    case PreconditionFailed = "412 precondition failed"
    case RequestTooLarge = "413 request entity too large"
    case RequestURITooLong = "414 request uri too long"
    case UnsupportedMediaType = "415 unsupported media type"
    case RequestRangeNotSatisfiable = "416 request range not satisfiable"
    case ExpectationFailed = "417 expectation failed"
    case TooManyRequests = "429 too many requests"
    
    // Server Error
    case InternalServerError = "500 internal server error"
    case NotImplemented = "501 not implemented"
    case BadGateway = "502 bad gateway"
    case ServiceUnavailable = "503 service unavailable"
    case GatewayTimeout = "504 gateway timeout"
    case HTTPVersionNotSupported = "505 http version not supported"
}