//
//  string_convertible.swift
//  twohundred
//
//  Created by Johannes Schriewer on 01/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

public extension UInt16 {
    func hexString(padded padded:Bool = true) -> String {
        let dict:[Character] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
        var result = ""
        var somethingWritten = false
        for i in 0...3 {
            let value = Int(self >> UInt16(((3 - i) * 4)) & 0xf)
            if !padded && !somethingWritten && value == 0 {
                continue
            }
            somethingWritten = true
            result.append(dict[value])
        }
        if (result.characters.count == 0) {
            return "0"
        }
        return result
    }
}

public extension UInt8 {
    func hexString(padded padded:Bool = true) -> String {
        let dict:[Character] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
        var result = ""
        var somethingWritten = false
        for i in 0...1 {
            let value = Int(self >> UInt8(((1 - i) * 4)) & 0xf)
            if !padded && !somethingWritten && value == 0 {
                continue
            }
            somethingWritten = true
            result.append(dict[value])
        }
        if (result.characters.count == 0) {
            return "0"
        }
        return result
    }
}
