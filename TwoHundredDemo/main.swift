//
//  main.swift
//  fileserver_app
//
//  Created by Johannes Schriewer on 29/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

#if os(Linux)
	import UnchainedGlibc
#else
	import Darwin
#endif

import TwoHundred

// print working dir to console
var cwd = [CChar](count: Int(FILENAME_MAX), repeatedValue: 0)
getcwd(&cwd, Int(FILENAME_MAX))
let dirString = String.fromCString(cwd)!
print("Working dir: \(dirString)")
        
// start server on all interfaces port 4567
print("Starting server on port 4567...")
let server = UnchainedFileServer(listenAddress: .Wildcard, port: 4567)
server.start()

while true {
	sleep(42)
}
