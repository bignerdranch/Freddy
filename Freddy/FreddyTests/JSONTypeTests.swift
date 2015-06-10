//
//  JSONTypeTests.swift
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/12/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import XCTest
import Freddy
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
