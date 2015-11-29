//
//  socket.swift
//  twohundred
//
//  Created by Johannes Schriewer on 21/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import XCTest
@testable import twohundred

class socketTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSocketListen() {
        let expectation = self.expectationWithDescription("testSocketListen")

        var fullfilled = false
        var data: String = ""
        print("Listening to socket")
        let sock = Socket(listen: .Wildcard, port: 4567) { (socket, char, connectionID, remote) -> Bool in
            data.append(UnicodeScalar(char))
            if data.hasSuffix("\r\n\r\n") {
                print("\(connectionID): \(data)")
                
                socket.send(.StringData("HTTP/1.1 404 Not found\r\nConnection: close\r\n\r\n"), connectionID: connectionID) { (data, connectionID) in
                    print("\(connectionID): Sent 404")
                    
                    if !fullfilled {
                        fullfilled = true
                        expectation.fulfill()
                    }
                }
                return false
            }
            return true
        }
        
        if sock == nil {
            XCTFail("Could not initialize listening socket")
        }
        
        system("curl http://127.0.0.1:4567")
        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    func testSocketConnect() {
        let sock = Socket(connect: "google.com", port: 80) { (socket, char, connectionID, remote) -> Bool in
            return true
        }
        
        if sock == nil {
            XCTFail("Could not connect socket")
        }
    }

}