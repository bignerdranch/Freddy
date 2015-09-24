//
//  JSONParserTests.swift
//  BNRSwiftJSONTests
//
//  Created by John Gallagher on 4/18/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
import BNRSwiftJSON
import Result

private func JSONFromString(s: String) -> Result<JSON, JSONParser.Error> {
    var parser = JSONParser(string: s)
    return parser.parse()
}

private func ~=(lhs: JSONParser.Error, rhs: JSONParser.Error) -> Bool {
    switch (lhs, rhs) {
    case (.EndOfStreamUnexpected, .EndOfStreamUnexpected):
        return true
    case let (.EndOfStreamGarbage(lOffset), .EndOfStreamGarbage(rOffset)):
        return lOffset == rOffset
    case let (.ExceededNestingLimit(lOffset), .ExceededNestingLimit(rOffset)):
        return lOffset == rOffset
    case let (.ValueInvalid(lOffset, lValue), .ValueInvalid(rOffset, rValue)):
        return lOffset == rOffset && lValue == rValue
    case let (.ControlCharacterUnrecognized(lOffset), .ControlCharacterUnrecognized(rOffset)):
        return lOffset == rOffset
    case let (.UnicodeEscapeInvalid(lOffset), .UnicodeEscapeInvalid(rOffset)):
        return lOffset == rOffset
    case let (.LiteralNilMisspelled(lOffset), .LiteralNilMisspelled(rOffset)):
        return lOffset == rOffset
    case let (.LiteralTrueMisspelled(lOffset), .LiteralTrueMisspelled(rOffset)):
        return lOffset == rOffset
    case let (.LiteralFalseMisspelled(lOffset), .LiteralFalseMisspelled(rOffset)):
        return lOffset == rOffset
    case let (.CollectionMissingSeparator(lOffset), .CollectionMissingSeparator(rOffset)):
        return lOffset == rOffset
    case let (.DictionaryMissingKey(lOffset), .DictionaryMissingKey(rOffset)):
        return lOffset == rOffset
    case let (.NumberMissingFractionalDigits(lOffset), .NumberMissingFractionalDigits(rOffset)):
        return lOffset == rOffset
    case let (.NumberSymbolMissingDigits(lOffset), .NumberSymbolMissingDigits(rOffset)):
        return lOffset == rOffset
    case (_, _):
        return false
    }
}

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
        case .Failure(JSONParser.Error.EndOfStreamGarbage(offset: 7)):
            break
        case .Failure(let error):
            XCTFail("Unexpected error \(error)")
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
        let string = "a b c d 😀 x y z"
        let result = JSONFromString("\"\(string)\"")
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, JSON.String(string))
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
        for (string, shouldBeInt) in [
            ("  0  ", 0),
            ("123", 123),
            ("  -20  ", -20),
        ] {
            switch JSONFromString(string) {
            case .Success(let value):
                XCTAssertEqual(value.int!, shouldBeInt)
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }

        for (string, shouldBeDouble) in [
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
            switch JSONFromString(string) {
            case .Success(let value):
                XCTAssertEqualWithAccuracy(value.double!, shouldBeDouble, accuracy: DBL_EPSILON)
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserRejectsInvalidNumbers() {
        for (string, expectedError) in [
            ("012",   JSONParser.Error.EndOfStreamGarbage(offset: 1)),
            ("0.1.2", JSONParser.Error.EndOfStreamGarbage(offset: 3)),
            ("-.123", JSONParser.Error.NumberSymbolMissingDigits(offset: 0)),
            (".123",  JSONParser.Error.ValueInvalid(offset: 0, character: ".")),
            ("1.",    JSONParser.Error.EndOfStreamUnexpected),
            ("1.0e",  JSONParser.Error.EndOfStreamUnexpected),
            ("1.0e+", JSONParser.Error.EndOfStreamUnexpected),
            ("1.0e-", JSONParser.Error.EndOfStreamUnexpected),
            ("0e1",   JSONParser.Error.EndOfStreamGarbage(offset: 1)),
        ] {
            switch JSONFromString(string) {
            case .Success:
                XCTFail("Unexpected success for \"\(string)\"")
            case .Failure(expectedError):
                break
            case .Failure(let error):
                XCTFail("Unexpected error \(error) in \(string)")
            }
        }
    }

    func testThatParserUnderstandsEmptyArrays() {
        let expect = JSON.Array([])
        for string in ["[]", "[  ]", "  [  ]  "] {
            let result = JSONFromString(string)
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
        for (string, expect) in [
            (" [ null   ,   \"foo\" ] ", [JSON.Null, .String("foo")]),
            ("[true,true,false]", [JSON.Bool(true), .Bool(true), .Bool(false)]),
            ("[ [\"nested\",null], [[\"doubly\",true]]   ]",
                [JSON.Array([.String("nested"), .Null]),
                 .Array([.Array([.String("doubly"), .Bool(true)])])])
        ] {
            let result = JSONFromString(string)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Array(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsEmptyObjects() {
        for string in ["{}", "  {   }  "] {
            let result = JSONFromString(string)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Dictionary([:]))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsSingleItemObjects() {
        for (string, expect) in [
            ("{\"a\":\"b\"}", ["a":JSON.String("b")]),
            ("{  \"foo\"  :  [null]  }", ["foo": JSON.Array([.Null])]),
            ("{  \"a\" : { \"b\": true }  }", ["a": JSON.Dictionary(["b":.Bool(true)])]),
        ] {
            let result = JSONFromString(string)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Dictionary(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testThatParserUnderstandsMultipleItemObjects() {
        for (string, expect) in [
            ("{\"a\":\"b\",\"c\":\"d\"}",
                ["a":JSON.String("b"),"c":.String("d")]),
            ("{  \"foo\"  :  [null]   ,   \"bar\":  true  }",
                ["foo": JSON.Array([.Null]), "bar": .Bool(true)]),
            ("{  \"a\" : { \"b\": true }, \"c\": { \"x\" : true, \"y\": null }  }",
                ["a": JSON.Dictionary(["b":.Bool(true)]),
                 "c": .Dictionary(["x": .Bool(true), "y": .Null])]),
        ] {
            let result = JSONFromString(string)
            switch result {
            case .Success(let value):
                XCTAssertEqual(value, JSON.Dictionary(expect))
            case .Failure(let error):
                XCTFail("Unexpected error \(error)")
            }
        }
    }
}
