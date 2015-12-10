//
//  string+whitespace.swift
//  twohundred
//
//  Created by Johannes Schriewer on 09/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

public extension String {
    public func stringByTrimmingWhitespace() -> String {
        let isWhitespace:(Character -> Bool) = { c in
            switch c {
            case " ", "\n", "\r\n", "\t": // ASCII
                return true
            case "\u{2028}", "\u{2029}": // Unicode paragraph seperators
                return true
            case "\u{00a0}", "\u{1680}", "\u{2000}"..."\u{200a}", "\u{202f}", "\u{205f}", "\u{3000}": // various spaces
                return true
            default:
                return false
            }
        }
        
        var startIndex:String.CharacterView.Index = self.startIndex
        for c in self.characters.enumerate() {
            if !isWhitespace(c.element) {
                startIndex = self.startIndex.advancedBy(c.index)
                break
            }
        }
        
        var endIndex = self.endIndex.advancedBy(-1)
        for _ in 0..<self.characters.count {
            if !isWhitespace(self.characters[endIndex]) {
                break
            }
            endIndex = endIndex.advancedBy(-1)
        }
        
        return self.substringWithRange(startIndex...endIndex)
    }
}
