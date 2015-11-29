//
//  request.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin

/// HTTP Request
public struct HTTPRequest {

    /// IP of the remote host
    public var remoteIP: IPAddress!
    
    /// Request header
    public var header: RequestHeader
    
    /// Body data, optional
    public var data:[UInt8]? = nil
}