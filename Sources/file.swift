//
//  file.swift
//  unchained
//
//  Created by Johannes Schriewer on 17/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin

public enum FileMode: String {
    case ReadOnly      = "rb"
    case WriteOnly     = "wb"
    case ReadAndWrite  = "r+b"
    case AppendOnly    = "ab"
    case AppendAndRead = "a+b"
}


public class File: OutputStreamType {
    private var fp: UnsafeMutablePointer<FILE> = nil
    private let closeWhenDeallocated: Bool
    
    public let filename: String?
    
    public enum Error: ErrorType {
        case FileNotFound
        case IOError
        case EndOfFile
    }
    
    public var position: Int {
        set(newValue) {
            fseek(self.fp, newValue, SEEK_SET)
        }
        
        get {
            return ftell(self.fp)
        }
    }

    public var size: Int {
        get {
            let offset = self.position
            fseek(self.fp, 0, SEEK_END)
            let size = self.position
            self.position = offset
            return size
        }
    }
    
    public init(filename: String, mode: FileMode) throws {
        self.fp = fopen(filename, mode.rawValue)
        self.closeWhenDeallocated = true
        self.filename = filename
        if self.fp == nil {
            throw Error.FileNotFound
        }
    }
    
    public init(fd: Int32, mode: FileMode, takeOwnerShip: Bool = false) throws {
        self.fp = fdopen(fd, mode.rawValue)
        self.closeWhenDeallocated = takeOwnerShip
        self.filename = nil
        if self.fp == nil {
            throw Error.FileNotFound
        }
    }
    
    public init(file: UnsafeMutablePointer<FILE>, takeOwnerShip: Bool = false) {
        self.fp = file
        self.filename = nil
        self.closeWhenDeallocated = takeOwnerShip
    }
    
    deinit {
        if self.closeWhenDeallocated {
            fclose(self.fp)
        }
    }
    
    public func write(string: String) {
        let bytes = string.utf8.count
        let written = fwrite(string, 1, bytes, self.fp)
        if bytes != written {
            // This protocol is dumb because it does not allow error return
            Log.error("IO error while writing to '\(self.filename)'!")
        }
    }
    
    public func write(data: [UInt8]) throws {
        let bytes = data.count
        let written = fwrite(data, 1, bytes, self.fp)
        if bytes != written {
            throw Error.IOError
        }
    }

    public func read(size: Int) throws -> String? {
        var buffer:[UInt8] = try self.read(size)
        buffer.append(0)
        return String(CString: UnsafePointer<CChar>(buffer), encoding: NSUTF8StringEncoding)
    }
    
    public func read(size: Int) throws -> [UInt8] {
        let buffer = [UInt8](count: size, repeatedValue: 0)
        let read = fread(UnsafeMutablePointer(buffer), 1, size, self.fp)
        guard read == size else {
            if feof(self.fp) == 0 {
                throw Error.IOError
            } else {
                throw Error.EndOfFile
            }
        }
        return buffer
    }
    
    public func readLine(stripLineBreak: Bool = false) throws -> String? {
        var buffer = [UInt8]()
        buffer.reserveCapacity(1024)
        
        var char: UInt8 = 0
        while true {
            let read = fread(&char, 1, 1, self.fp)
            guard read == 1 else {
                if feof(self.fp) == 0 {
                    throw Error.IOError
                } else if buffer.count == 0 {
                    throw Error.EndOfFile
                }
                break
            }
            if char == 10 {
                // linebreak found
                if !stripLineBreak {
                    buffer.append(10)
                }
                break
            }
            if char == 13 {
                continue // skip cr
            }
            buffer.append(char)
        }
        
        
        buffer.append(0)
        return String(CString: UnsafePointer<CChar>(buffer), encoding: NSUTF8StringEncoding)
    }
}

