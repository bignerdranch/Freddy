//
//  JSONTypeTests.swift
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/12/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
import Freddy

class JSONTypeTests: XCTestCase {
    
    func testCastInitializeArray() {
        let array = [ JSON.Int(1), JSON.Int(2), JSON.Int(3) ]
        let expected = JSON.Array(array)
        let json = JSON(array)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeAnyCollection() {
        let collection = (1 ... 3).lazy.map { JSON.Int($0) }
        let expected = JSON.Array([ JSON.Int(1), JSON.Int(2), JSON.Int(3) ])
        let json = JSON(collection)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeDictionary() {
        let dictionary = [ "foo": JSON.Int(1), "bar": JSON.Int(2), "baz": JSON.Int(3) ]
        let expected = JSON.Dictionary(dictionary)
        let json = JSON(dictionary)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeAnyDictionary() {
        let dictionary = [ "foo": 1, "bar": 2, "baz": 3 ]
        let pairCollection = dictionary.lazy.map { (key, value) in
            (key, JSON(value * 2))
        }
        let expected = JSON.Dictionary([ "foo": JSON.Int(2), "bar": JSON.Int(4), "baz": JSON.Int(6) ])
        let json = JSON(pairCollection)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeDouble() {
        let double = 42.0 as Double
        let expected = JSON.Double(double)
        let json = JSON(double)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeInt() {
        let int = 65535 as Int
        let expected = JSON.Int(int)
        let json = JSON(int)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeString() {
        let string = "Don't Panic"
        let expected = JSON.String(string)
        let json = JSON(string)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeBool() {
        let bool = false
        let expected = JSON.Bool(bool)
        let json = JSON(bool)
        XCTAssertEqual(json, expected)
    }

    func testLiteralConversion() {
        let valueNotLiteral: JSON = .Dictionary([
            "someKey": .Array([
                .Dictionary([ "children": .Array([ .String("a string") ]) ]),
                .Dictionary([ "children": .Array([ .String("\u{00E9}"), .String("\u{00E9}") ]) ]),
                .Dictionary([ "children": .Array([ .String("\u{1F419}"), .String("\u{1F419}") ]) ]),
                .Dictionary([ "children": .Array([ .Double(42.0), .Int(65535), .Bool(true), .Null ]) ])
            ])
        ])
        
        // Swift only calls the Unicode literal initializers under
        // Release-mode optimization, so they're explicity invoked for the sake
        // of test coverage.
        let valueLiterally = [
            "someKey": [
                [ "children": [ "a string" ] ],
                [ "children": [ "é", JSON(unicodeScalarLiteral: "é") ] ],
                [ "children": [ "🐙", JSON(extendedGraphemeClusterLiteral: "🐙") ] ],
                [ "children": [ 42.0, 65535, true, nil ] ]
            ]
        ] as JSON
        
        XCTAssertEqual(valueLiterally, valueNotLiteral)
    }
    
    
}
