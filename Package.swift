//
//  Package.swift
//  twohundred
//
//  Created by Johannes Schriewer on 03/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "TwoHundred",
	targets: [
	 	Target(name:"TwoHundredTests", dependencies: [.Target(name: "TwoHundred")]),
	 	Target(name:"TwoHundredDemo", dependencies: [.Target(name: "TwoHundred")]),
        Target(name:"TwoHundred")
	],
	dependencies: [
		.Package(url:"https://github.com/dunkelstern/Adler32.git", majorVersion: 0),
		.Package(url:"https://github.com/dunkelstern/UnchainedIPAddress.git", majorVersion: 0),
		.Package(url:"https://github.com/dunkelstern/UnchainedDate.git", majorVersion: 0),
		.Package(url:"https://github.com/dunkelstern/UnchainedLogger.git", majorVersion: 0),
		.Package(url:"https://github.com/dunkelstern/libUnchainedSocket.git", majorVersion: 0)
	]
)

#if os(Linux)
	package.dependencies.appendContentsOf([
		.Package(url:"https://github.com/dunkelstern/BlocksRuntime.git", majorVersion: 0),
		.Package(url:"https://github.com/dunkelstern/UnchainedGlibc.git", majorVersion: 0)
	])
#endif
