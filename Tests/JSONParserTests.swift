//
//  JSONParserTests.swift
//  FreddyTests
//
//  Created by John Gallagher on 4/18/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
import Freddy

private func ==(lhs: JSONParser.Error, rhs: JSONParser.Error) -> Bool {
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

    private func JSONFromString(s: String) throws -> JSON {
        var parser = JSONParser(string: s)
        return try parser.parse()
    }

    func testThatParserThrowsAnErrorForAnEmptyNSData() {
        
        do {
            _ = try JSONFromString("")
            XCTFail("Unexpectedly did not throw an error") 
        } catch let error as JSONParser.Error {
            XCTAssert(error == JSONParser.Error.EndOfStreamUnexpected)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserThrowsErrorForInsufficientNSData() {
        let hex: [UInt8] = [0x7B]
        let data = NSData(bytes: hex, length: hex.count)

        do {
            try JSONParser.createJSONFromData(data)
            XCTFail("Unexpectedly did not throw an error")
        } catch JSONParser.Error.EndOfStreamUnexpected {
            return
        } catch {
            XCTFail("Incorrect error received.: \(error)")
        }
    }
    
    func testThatParserCompletesWithSingleZero() {
        guard let data = "0".dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Cannot create data from string")
            return
        }

        do {
            try JSONParser.createJSONFromData(data)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserCompletesWithBOMAndSingleZero() {
        let hex: [UInt8] = [0xEF, 0xBB, 0xBF, 0x30]
        let data = NSData(bytes: hex, length: hex.count)

        do {
            try JSONParser.createJSONFromData(data)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsNull() {
        let value = try! JSONFromString("null")
        XCTAssertEqual(value, JSON.Null)
    }

    func testThatParserSkipsLeadingWhitespace() {
        let value = try! JSONFromString("   \t\r\nnull")
        XCTAssertEqual(value, JSON.Null)
    }

    func testThatParserAllowsTrailingWhitespace() {
        let value = try! JSONFromString("null   ")
        XCTAssertEqual(value, JSON.Null)
    }

    func testThatParserFailsWhenTrailingDataIsPresent() {
        do {
            _ = try JSONFromString("null   true")
        } catch JSONParser.Error.EndOfStreamGarbage(let offset) {
            XCTAssertEqual(offset, 7)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsTrue() {
        let value = try! JSONFromString("true")
        XCTAssertEqual(value, JSON.Bool(true))
    }

    func testThatParserUnderstandsFalse() {
        let value = try! JSONFromString("false")
        XCTAssertEqual(value, JSON.Bool(false))
    }

    func testThatParserUnderstandsStringsWithoutEscapes() {
        let string = "a b c d 😀 x y z"
        let value = try! JSONFromString("\"\(string)\"")
        XCTAssertEqual(value, JSON.String(string))
    }

    func testThatParserUnderstandsStringsWithEscapedCharacters() {
        let expect = " \" \\ / \n \r \t \u{000c} \u{0008} "
        let value = try! JSONFromString("\" \\\" \\\\ \\/ \\n \\r \\t \\f \\b \"")
        XCTAssertEqual(value, JSON.String(expect))
    }

    func testThatParserUnderstandsStringsWithEscapedUnicode() {
        // try 1-, 2-, and 3-byte UTF8 sequences
        let expect = "\u{0060}\u{012a}\u{12AB}"
        let value = try! JSONFromString("\"\\u0060\\u012a\\u12AB\"")
        XCTAssertEqual(value, JSON.String(expect))
    }

    func testThatParserUnderstandsNumbers() {
        for (string, shouldBeInt) in [
            ("  0  ", 0),
            ("123", 123),
            ("  -20  ", -20),
        ] {
            XCTAssertEqual(try! JSONFromString(string).int(), shouldBeInt)
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
            XCTAssertEqualWithAccuracy(try! JSONFromString(string).double(), shouldBeDouble, accuracy: DBL_EPSILON)
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
            do {
                _ = try JSONFromString(string)
            } catch let error as JSONParser.Error {
                XCTAssert(error == expectedError)
            } catch {
                XCTFail("Unexpected error \(error) in \(string)")
            }
        }
    }

    func testThatParserUnderstandsEmptyArrays() {
        let expect = JSON.Array([])
        for string in ["[]", "[  ]", "  [  ]  "] {
            let value = try! JSONFromString(string)
            XCTAssertEqual(value, expect)
        }
    }

    func testThatParserUnderstandsSingleItemArrays() {
        for (s, expect) in [
            (" [ null ] ", [JSON.Null]),
            ("[true]", [JSON.Bool(true)]),
            ("[ [\"nested\"]]", [JSON.Array([.String("nested")])])
        ] {
            let value = try! JSONFromString(s)
            XCTAssertEqual(value, JSON.Array(expect))
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
            let value = try! JSONFromString(string)
            XCTAssertEqual(value, JSON.Array(expect))
        }
    }

    func testThatParserUnderstandsEmptyObjects() {
        for string in ["{}", "  {   }  "] {
            let value = try! JSONFromString(string)
            XCTAssertEqual(value, JSON.Dictionary([:]))
        }
    }

    func testThatParserUnderstandsSingleItemObjects() {
        for (string, expect) in [
            ("{\"a\":\"b\"}", ["a":JSON.String("b")]),
            ("{  \"foo\"  :  [null]  }", ["foo": JSON.Array([.Null])]),
            ("{  \"a\" : { \"b\": true }  }", ["a": JSON.Dictionary(["b":.Bool(true)])]),
        ] {
            let value = try! JSONFromString(string)
            XCTAssertEqual(value, JSON.Dictionary(expect))
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
            let value = try! JSONFromString(string)
            XCTAssertEqual(value, JSON.Dictionary(expect))
        }
    }

    func testThatParserFailsForUnsupportedEncodings() {

        let unsupportedEncodings: [JSONEncodingDetector.Encoding] = [
            .UTF16LE,
            .UTF16BE,
            .UTF32LE,
            .UTF32BE
        ]
        let fixtures = JSONEncodingUTFTestFixtures()

        for encoding in unsupportedEncodings {
            let hex = fixtures.hexArray(encoding, includeBOM: false)
            let data = NSData(bytes: hex, length: hex.count)
            let hexWithBOM = fixtures.hexArray(encoding, includeBOM: true)
            let dataWithBOM = NSData(bytes: hexWithBOM, length: hexWithBOM.count)
            do {
                try JSONParser.createJSONFromData(data)
                try JSONParser.createJSONFromData(dataWithBOM)
                XCTFail("Unexpectedly did not throw an error")
            } catch JSONParser.Error.InvalidUnicodeStreamEncoding(_) {
                break
            } catch {
                XCTFail("Incorrect error received.: \(error)")
            }
        }
    }

    func testThatParserAcceptsUTF16SurrogatePairs() {
        for (jsonString, expected) in [
            ("\"\\uD801\\uDC37\"", "𐐷"),
            ("\"\\ud83d\\ude39\\ud83d\\udc8d\"", "😹💍"),
        ] {
            do {
                let json = try JSONFromString(jsonString)
                let decoded: String = try json.decode()
                XCTAssertEqual(decoded, expected)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testThatParserRejectsInvalidUTF16SurrogatePairs() {
        for invalidPairString in [
            "\"\\ud800\\ud123\"",
            "\"\\ud800\"",
            "\"\\ud800abc\"",
        ] {
            do {
                let _ = try JSONFromString(invalidPairString)
                XCTFail("Unexpectedly parsed invalid surrogate pair")
            } catch JSONParser.Error.UnicodeEscapeInvalid {
                // do nothing - this is the expected error
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
