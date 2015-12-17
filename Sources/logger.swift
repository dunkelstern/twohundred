//
//  logger.swift
//  unchained
//
//  Created by Johannes Schriewer on 17/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Darwin

public class Log {
    public static var logLevel: LogLevel = .Debug

    public static var logFileName: String? = nil {
        didSet {
            self.logFile = nil
            if let filename = self.logFileName {
                do {
                    self.logFile = try File(filename: filename, mode: .AppendOnly)
                } catch {
                    self.logFileName = nil
                }
            }
        }
    }
    
    private static var logFile: File? = nil

    public enum LogLevel: Int {
        case Debug = 0
        case Info  = 1
        case Warn  = 2
        case Error = 3
        case Fatal = 4
    }

    public class func debug(msg: Streamable...) {
        guard Log.logLevel.rawValue <= LogLevel.Debug.rawValue else {
            return
        }
        self.log("DEBUG", msg)
    }

    public class func info(msg: Streamable...) {
        guard Log.logLevel.rawValue <= LogLevel.Info.rawValue else {
            return
        }
        self.log("INFO ", msg)
    }

    public class func warn(msg: Streamable...) {
        guard Log.logLevel.rawValue <= LogLevel.Warn.rawValue else {
            return
        }
        self.log("WARN ", msg)
    }

    public class func error(msg: Streamable...) {
        guard Log.logLevel.rawValue <= LogLevel.Error.rawValue else {
            return
        }
        self.log("ERROR", msg)
    }

    public class func fatal(msg: Streamable...) {
        guard Log.logLevel.rawValue <= LogLevel.Fatal.rawValue else {
            return
        }
        self.log("FATAL", msg)
    }
    
    // MARK: - Private
    private class func log(level: String, _ msg: [Streamable]) {
        let date = Date(timestamp: time(nil))

        if self.logFile != nil {
            date.isoDateString!.writeTo(&logFile!)
            " [\(level)]: ".writeTo(&logFile!)
            for item in msg {
                item.writeTo(&logFile!)
                " ".writeTo(&logFile!)
            }
            "\n".writeTo(&logFile!)
        } else {
            if let logFileName = self.logFileName {
                do {
                    self.logFile = try File(filename: logFileName, mode: .AppendOnly)
                    self.log(level, msg)
                    return
                } catch {
                    print("\(date.isoDateString!) [FATAL]: Could not open logfile \(logFileName)!")
                }
            }
            
            print("\(date.isoDateString!) [\(level)]: ", terminator: "")
            for item in msg {
                var tmp = ""
                item.writeTo(&tmp)
                print(tmp + " ", terminator: "")
            }
            print("")
            
        }
    }
    
    private init() {
        
    }
}
