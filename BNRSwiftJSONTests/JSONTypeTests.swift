//
//  JSONTypeTests.swift
//  BNRSwiftJSONTests
//
//  Created by Zachary Waldowski on 5/12/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
import BNRSwiftJSON
import Foundation

class JSONTypeTests: XCTestCase {
    
    func testLiteralConversion() {
        let valueNotLiteral: JSON = .Dictionary([
            "children": .Array([
                .Dictionary([ "children": .Array([]) ]),
                .Dictionary([ "children": .Array([]) ])
            ])
        ])
        
        let valueLiteral: JSON = [
            "children": [
                [ "children": [] ],
                [ "children": [] ]
            ]
        ]
        
        XCTAssertEqual(valueLiteral, valueNotLiteral)
    }
    
    
}
