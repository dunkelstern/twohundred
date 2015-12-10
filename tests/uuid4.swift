//
//  uuid4.swift
//  twohundred
//
//  Created by Johannes Schriewer on 10/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

import XCTest
@testable import twohundred

class uuidTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUUIDFromString() {
        let uuid = UUID4(string: "de305d54-75b4-431b-adb2-eb6b9e546014")
        XCTAssertNotNil(uuid)
        XCTAssert(uuid!.description == "DE305D54-75B4-431B-ADB2-EB6B9E546014")
    }

    func testUUIDFromStringFail1() {
        let uuid = UUID4(string: "de305d54-75b4-431badb2-eb6b9e546014")
        XCTAssertNil(uuid)
    }

    func testUUIDFromStringFail2() {
        let uuid = UUID4(string: "de305d54-75b4-431b-adb2-b6b9e546014")
        XCTAssertNil(uuid)
    }

    func testUUIDFromStringFail3() {
        let uuid = UUID4(string: "de305d54-75b4-431b-adb2-b6b9e54601")
        XCTAssertNil(uuid)
    }

}