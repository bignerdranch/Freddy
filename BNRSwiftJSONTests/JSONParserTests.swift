//
//  JSONParserTests.swift
//  BNRSwiftJSONTests
//
//  Created by John Gallagher on 4/18/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import XCTest
import BNRSwiftJSON

class JSONParserTests: XCTestCase {

    func testThatParserUnderstandsNull() {
        let result = JSONFromString("null")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.Null)
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserSkipsLeadingWhitespace() {
        let result = JSONFromString("   \t\r\nnull")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.Null)
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserAllowsTrailingWhitespace() {
        let result = JSONFromString("null   ")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.Null)
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserFailsWhenTrailingDataIsPresent() {
        let result = JSONFromString("null   true")
        switch result {
        case .Success:
            XCTFail("Unexpected success")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.ErrorCode.CouldNotParseJSON.rawValue)
        }
    }

    func testThatParserUnderstandsTrue() {
        let result = JSONFromString("true")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.Bool(true))
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsFalse() {
        let result = JSONFromString("false")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.Bool(false))
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsStringsWithoutEscapes() {
        let s = "a b c d 😀 x y z"
        let result = JSONFromString("\"\(s)\"")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.String(s))
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsStringsWithEscapedCharacters() {
        let expect = " \" \\ / \n \r \t \u{000c} \u{0008} "
        let result = JSONFromString("\" \\\" \\\\ \\/ \\n \\r \\t \\f \\b \"")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.String(expect))
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsStringsWithEscapedUnicode() {
        // try 1-, 2-, and 3-byte UTF8 sequences
        let expect = "\u{0060}\u{012a}\u{12AB}"
        let result = JSONFromString("\"\\u0060\\u012a\\u12AB\"")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.String(expect))
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsNumbers() {
        for (s, shouldBeInt) in [
            ("  0  ", 0),
            ("123", 123),
            ("  -20  ", -20),
        ] {
            switch JSONFromString(s) {
            case .Success(let value):
                XCTAssertEqual(value.int!, shouldBeInt)
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }

        for (s, shouldBeDouble) in [
            ("  -0  ", -0.0),
            ("  -0.0  ", 0.0),
            ("123.0", 123.0),
            ("123.456", 123.456),
            ("-123.456", -123.456),
            ("123e2", 123e2),
            ("123.45E2", 123.45E2),
            ("123.45e+2", 123.45e+2),
            ("-123.45e-2", -123.45e-2),
        ] {
            switch JSONFromString(s) {
            case .Success(let value):
                XCTAssertEqualWithAccuracy(value.double!, shouldBeDouble, accuracy: DBL_EPSILON)
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserRejectsInvalidNumbers() {
        for s in [
            "012",
            "0.1.2",
            "-.123",
            ".123",
            "1.",
            "1.0e",
            "1.0e+",
            "1.0e-",
            "0e1",
        ] {
            switch JSONFromString(s) {
            case .Success:
                XCTFail("Unexpected success for \"\(s)\"")
            case .Failure(let error):
                XCTAssertEqual(error.code, JSON.ErrorCode.CouldNotParseJSON.rawValue)
            }
        }
    }

    func testThatParserUnderstandsEmptyArrays() {
        let expect = JSON.Array([])
        for s in ["[]", "[  ]", "  [  ]  "] {
            let result = JSONFromString(s)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, expect)
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsSingleItemArrays() {
        for (s, expect) in [
            (" [ null ] ", [JSON.Null]),
            ("[true]", [JSON.Bool(true)]),
            ("[ [\"nested\"]]", [JSON.Array([.String("nested")])])
        ] {
            let result = JSONFromString(s)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Array(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsMultipleItemArrays() {
        for (s, expect) in [
            (" [ null   ,   \"foo\" ] ", [JSON.Null, .String("foo")]),
            ("[true,true,false]", [JSON.Bool(true), .Bool(true), .Bool(false)]),
            ("[ [\"nested\",null], [[\"doubly\",true]]   ]",
                [JSON.Array([.String("nested"), .Null]),
                 .Array([.Array([.String("doubly"), .Bool(true)])])])
        ] {
            let result = JSONFromString(s)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Array(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsEmptyObjects() {
        for s in ["{}", "  {   }  "] {
            let result = JSONFromString(s)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Dictionary([:]))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsSingleItemObjects() {
        for (s, expect) in [
            ("{\"a\":\"b\"}", ["a":JSON.String("b")]),
            ("{  \"foo\"  :  [null]  }", ["foo": JSON.Array([.Null])]),
            ("{  \"a\" : { \"b\": true }  }", ["a": JSON.Dictionary(["b":.Bool(true)])]),
        ] {
            let result = JSONFromString(s)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Dictionary(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsMultipleItemObjects() {
        for (s, expect) in [
            ("{\"a\":\"b\",\"c\":\"d\"}",
                ["a":JSON.String("b"),"c":.String("d")]),
            ("{  \"foo\"  :  [null]   ,   \"bar\":  true  }",
                ["foo": JSON.Array([.Null]), "bar": .Bool(true)]),
            ("{  \"a\" : { \"b\": true }, \"c\": { \"x\" : true, \"y\": null }  }",
                ["a": JSON.Dictionary(["b":.Bool(true)]),
                 "c": .Dictionary(["x": .Bool(true), "y": .Null])]),
        ] {
            let result = JSONFromString(s)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Dictionary(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }
}
