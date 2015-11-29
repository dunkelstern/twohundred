//
//  date.swift
//  twohundred
//
//  Created by Johannes Schriewer on 26/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

import XCTest
@testable import twohundred

class dateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testISODateParsing() {
        if let date = Date(isoDateString: "1984-01-24T12:34:00Z") {
            XCTAssert(date.timestamp == 443795640)
        } else {
            XCTFail("Failure to parse date")
        }
    }
    
    func testTimeStampToISODate() {
        let date = Date(timestamp: 443795640)
        XCTAssertNotNil(date.isoDateString)
        XCTAssert(date.isoDateString == "1984-01-24T12:34:00Z")
    }
    
    func testRFC822DateParsing() {
        if let date = Date(rfc822DateString: "Tue, 24 Jan 1984 12:34:00 +0000") {
            XCTAssert(date.timestamp == 443795640)
        } else {
            XCTFail("Failure to parse date")
        }
    }
    
    func testTimeStampToRFC822Date() {
        let date = Date(timestamp: 443795640)
        XCTAssertNotNil(date.isoDateString)
        XCTAssert(date.rfc822DateString == "Tue, 24 Jan 1984 12:34:00 +0000")
    }

}