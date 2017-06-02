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
        let array: [JSON] = [1, 2, 3]
        let expected = JSON.array(array)
        let json = JSON(array)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeAnyCollection() {
        let collection = (1 ... 3).lazy.map { JSON.int($0) }
        let expected: JSON = .array([1, 2, 3])
        let json = JSON(collection)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeDictionary() {
        let dictionary: [String:JSON] = ["foo": 1, "bar": 2, "baz": 3]
        let expected = JSON.dictionary(dictionary)
        let json = JSON(dictionary)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeAnyDictionary() {
        let dictionary = ["foo": 1, "bar": 2, "baz": 3]
        let pairCollection = dictionary.lazy.map { pair in
            (pair.key, JSON(pair.value * 2))
        }
        let expected: JSON = .dictionary(["foo": 2, "bar": 4, "baz": 6])
        let json = JSON(pairCollection)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeDouble() {
        let double = 42.0 as Double
        let expected = JSON.double(double)
        let json = JSON(double)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeInt() {
        let int = 65535 as Int
        let expected = JSON.int(int)
        let json = JSON(int)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeString() {
        let string = "Don't Panic"
        let expected = JSON.string(string)
        let json = JSON(string)
        XCTAssertEqual(json, expected)
    }

    func testCastInitializeBool() {
        let bool = false
        let expected = JSON.bool(bool)
        let json = JSON(bool)
        XCTAssertEqual(json, expected)
    }

    func testLiteralConversion() {
        let valueNotLiteral: JSON = .dictionary([
            "someKey": .array([
                .dictionary([ "children": .array([ .string("a string") ]) ]),
                .dictionary([ "children": .array([ .string("\u{00E9}"), .string("\u{00E9}") ]) ]),
                .dictionary([ "children": .array([ .string("\u{1F419}"), .string("\u{1F419}") ]) ]),
                .dictionary([ "children": .array([ .double(42.0), .int(65535), .bool(true), .null ]) ])
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
