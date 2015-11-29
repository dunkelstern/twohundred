//
//  fileserver.swift
//  fileserver
//
//  Created by Johannes Schriewer on 29/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin
import twohundred

class UnchainedFileServer: TwoHundredServer {
    override func handleRequest(request: HTTPRequest) -> HTTPResponse {
        var url = request.header.url.substringFromIndex(request.header.url.characters.startIndex.advancedBy(1)) // cut off leading slash
        if url.hasSuffix("/") {
            url = url.substringToIndex(url.endIndex.predecessor())
        }
        if url.characters.count == 0 {
            // index
            print("\(request.header.method.rawValue) \(request.header.url) -> Directory")
            return self.dirListing(".")
        }
        url = url.urlDecodedString()
        
        var s = stat()
        if stat(url, &s) == 0 {
            if s.st_mode & S_IFDIR != 0 {
                // directory, generate listing
                print("\(request.header.method.rawValue) \(request.header.url) -> Directory")
                return self.dirListing(url)
            }
            
            // try to guess the content type
            var contentType = "application/octet-stream"
            if url.hasSuffix(".html") {
                contentType = "text/html"
            }
            if url.hasSuffix(".js") {
                contentType = "text/javascript"
            }
            if url.hasSuffix(".css") {
                contentType = "text/css"
            }
            if url.hasSuffix(".png") {
                contentType = "image/png"
            }
            if url.hasSuffix(".jpg") || url.hasSuffix(".jpeg") {
                contentType = "image/jpeg"
            }
            if url.hasSuffix(".gif") {
                contentType = "image/gif"
            }
            
            print("\(request.header.method.rawValue) \(request.header.url) -> Sending file")
            
            // return a file response
            return HTTPResponse(.Ok, body: [.File(url)], contentType: contentType)
        } else {
            print("\(request.header.method.rawValue) \(request.header.url) -> 404")
            
            // return a 404, we don't know the path
            return HTTPResponse(.NotFound)
        }
    }
    
    private func dirListing(path: String) -> HTTPResponse {
        // list directory
        var dp = opendir(path)
        guard dp != nil else {
            return HTTPResponse(.InternalServerError)
        }
        
        // don't forget to close the directory
        defer {
            closedir(dp)
        }
        
        // file list generation
        var files = [(String, String)]()
        var ep = readdir(dp)
        while ep != nil {
            let nameBuffer = ep.memory.d_name
            let nameLen = Int(ep.memory.d_namlen)
            
            // this is very ugly, but i don't know of a better way
            var copy: [CChar] = Array()
            let mirror = Mirror(reflecting: nameBuffer)
            var i = 0
            for (_, value) in mirror.children {
                copy.append(value as! Int8)
                i++
                if i == nameLen {
                    break
                }
            }
            copy.append(0) // zero terminate buffer
            
            // convert buffer back to string
            if let name = String.fromCString(copy) {
                if (path == "." && name == "..") || name == "." {
                    // skip those
                } else {
                    if name == ".." {
                        files.append(("\(path)/..", "&lt;Parent Directory&gt;"))
                    } else {
                        // url encode at least the last component, browsers do the rest usually
                        files.append(("\(path)/\(name.urlEncodedString())", name))
                    }
                }
            }
            
            // next item
            ep = readdir(dp)
        }
        
        // generate a crude html view of the listing
        var result = "<html><head><title>Listing of \(path)</title></head><body>"
        result += "<h1>Listing '\(path)'</h1><ul>"
        
        for file in files {
            result += "<li><a href='/\(file.0)'>\(file.1)</a></li>\n"
        }
        
        result += "</ul></body></html>"
        
        // return a string response
        return HTTPResponse(.Ok, body: [.StringData(result)], contentType: "text/html")
    }
}
