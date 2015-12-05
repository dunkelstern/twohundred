//
//  Package.swift
//  twohundred
//
//  Created by Johannes Schriewer on 03/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import PackageDescription

let package = Package(
	dependencies: [
		.Package(url: "Dependencies/dispatch", majorVersion: 1)
	],
    name: "twohundred"
)
