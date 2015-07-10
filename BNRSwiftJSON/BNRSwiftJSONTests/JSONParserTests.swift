//
//  JSONParserTests.swift
//  BNRSwiftJSONTests
//
//  Created by John Gallagher on 4/18/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import XCTest
import BNRSwiftJSON
import Box

// In at least one unit test file, Swift 1.2 requires importing the respective
// platform UI toolkit in order to copy all the overlay libraries into the
// test target.
#if os(OSX)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

private extension JSON.Error {
    var parseError: BNRSwiftJSON.ParseError? {
        switch self {
        case .ParseError(let e): return e
        default: return nil
        }
    }
}

class JSONParserTests: XCTestCase {

    func testThatParserUnderstandsNull() {
        let result = JSONFromString("null")
        BNRAssertEqual(result.value, JSON.Null)
    }

    func testThatParserSkipsLeadingWhitespace() {
        let result = JSONFromString("   \t\r\nnull")
        BNRAssertEqual(result.value, JSON.Null)
    }

    func testThatParserAllowsTrailingWhitespace() {
        let result = JSONFromString("null   ")
        BNRAssertEqual(result.value, JSON.Null)
    }

    func testThatParserFailsWhenTrailingDataIsPresent() {
        let result = JSONFromString("null   true")
        BNRAssertEqual(result.error?.parseError, ParseError.UnexpectedTrailingData)
    }

    func testThatParserUnderstandsTrue() {
        let result = JSONFromString("true")
        BNRAssertEqual(result.value, JSON.Bool(true))
    }

    func testThatParserUnderstandsFalse() {
        let result = JSONFromString("false")
        BNRAssertEqual(result.value, JSON.Bool(false))
    }

    func testThatParserUnderstandsStringsWithoutEscapes() {
        let s = "a b c d 😀 x y z"
        let result = JSONFromString("\"\(s)\"")
        BNRAssertEqual(result.value, JSON.String(s))
    }

    func testThatParserUnderstandsStringsWithEscapedCharacters() {
        let expect = " \" \\ / \n \r \t \u{000c} \u{0008} "
        let result = JSONFromString("\" \\\" \\\\ \\/ \\n \\r \\t \\f \\b \"")
        BNRAssertEqual(result.value, JSON.String(expect))
    }

    func testThatParserUnderstandsStringsWithEscapedUnicode() {
        // try 1-, 2-, and 3-byte UTF8 sequences
        let expect = "\u{0060}\u{012a}\u{12AB}"
        let result = JSONFromString("\"\\u0060\\u012a\\u12AB\"")
        BNRAssertEqual(result.value, JSON.String(expect))
    }

    func testThatParserUnderstandsNumbers() {
        for (s, shouldBeInt) in [
            ("  0  ", 0),
            ("123", 123),
            ("  -20  ", -20),
        ] {
            switch JSONFromString(s) {
            case .Success(let boxed):
                XCTAssertEqual(boxed.value.int!, shouldBeInt)
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
            let result = JSONFromString(s)
            BNRAssertEqualWithAccuracy(result.value?.double, shouldBeDouble, DBL_EPSILON)
        }
    }

    func testThatParserRejectsNumbersWithTrailingNumbers() {
        for s in [
            "012",
            "0.1.2",
        ] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.error?.parseError, ParseError.UnexpectedTrailingData)
        }
    }

    func testThatParserRejectsNumbersThatBeginWithPeriod() {
        for (s, pos) in [
            ("-.123", 1),
            (".123", 0),
        ] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.error?.parseError, ParseError.InvalidCharacter(pos))
        }
    }

    func testThatParserRejectsNumbersThatEndAbruptly() {
        for s in [
            "1.",
            "1.0e",
            "1.0e+",
            "1.0e-",
        ] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.error?.parseError, ParseError.UnexpectedEndOfInput)
        }
    }

    func testThatParserRejectsScientficNotationWithZeroCoefficient() {
        let result = JSONFromString("0e1")
        BNRAssertEqual(result.error?.parseError, ParseError.UnexpectedTrailingData)
    }

    func testThatParserUnderstandsEmptyArrays() {
        let expect = JSON.Array([])
        for s in ["[]", "[  ]", "  [  ]  "] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.value, expect)
        }
    }

    func testThatParserUnderstandsSingleItemArrays() {
        for (s, expect) in [
            (" [ null ] ", [JSON.Null]),
            ("[true]", [JSON.Bool(true)]),
            ("[ [\"nested\"]]", [JSON.Array([.String("nested")])])
        ] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.value, JSON.Array(expect))
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
            BNRAssertEqual(result.value, JSON.Array(expect))
        }
    }

    func testThatParserUnderstandsEmptyObjects() {
        for s in ["{}", "  {   }  "] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.value, JSON.Dictionary([:]))
        }
    }

    func testThatParserUnderstandsSingleItemObjects() {
        for (s, expect) in [
            ("{\"a\":\"b\"}", ["a":JSON.String("b")]),
            ("{  \"foo\"  :  [null]  }", ["foo": JSON.Array([.Null])]),
            ("{  \"a\" : { \"b\": true }  }", ["a": JSON.Dictionary(["b":.Bool(true)])]),
        ] {
            let result = JSONFromString(s)
            BNRAssertEqual(result.value, JSON.Dictionary(expect))
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
            BNRAssertEqual(result.value, JSON.Dictionary(expect))
        }
    }
}
