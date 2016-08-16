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
    case (.endOfStreamUnexpected, .endOfStreamUnexpected):
        return true
    case let (.endOfStreamGarbage(lOffset), .endOfStreamGarbage(rOffset)):
        return lOffset == rOffset
    case let (.exceededNestingLimit(lOffset), .exceededNestingLimit(rOffset)):
        return lOffset == rOffset
    case let (.valueInvalid(lOffset, lValue), .valueInvalid(rOffset, rValue)):
        return lOffset == rOffset && lValue == rValue
    case let (.controlCharacterUnrecognized(lOffset), .controlCharacterUnrecognized(rOffset)):
        return lOffset == rOffset
    case let (.unicodeEscapeInvalid(lOffset), .unicodeEscapeInvalid(rOffset)):
        return lOffset == rOffset
    case let (.literalNilMisspelled(lOffset), .literalNilMisspelled(rOffset)):
        return lOffset == rOffset
    case let (.literalTrueMisspelled(lOffset), .literalTrueMisspelled(rOffset)):
        return lOffset == rOffset
    case let (.literalFalseMisspelled(lOffset), .literalFalseMisspelled(rOffset)):
        return lOffset == rOffset
    case let (.collectionMissingSeparator(lOffset), .collectionMissingSeparator(rOffset)):
        return lOffset == rOffset
    case let (.dictionaryMissingKey(lOffset), .dictionaryMissingKey(rOffset)):
        return lOffset == rOffset
    case let (.numberMissingFractionalDigits(lOffset), .numberMissingFractionalDigits(rOffset)):
        return lOffset == rOffset
    case let (.numberSymbolMissingDigits(lOffset), .numberSymbolMissingDigits(rOffset)):
        return lOffset == rOffset
    case (_, _):
        return false
    }
}

class JSONParserTests: XCTestCase {

    func testThatParserThrowsAnErrorForAnEmptyNSData() {
        
        do {
            _ = try JSONParser.parse("")
            XCTFail("Unexpectedly did not throw an error") 
        } catch let error as JSONParser.Error {
            XCTAssert(error == JSONParser.Error.endOfStreamUnexpected)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserThrowsErrorForInsufficientNSData() {
        let hex: [UInt8] = [0x7B]
        let data = Data(bytes: UnsafePointer<UInt8>(hex), count: hex.count)

        do {
            _ = try JSONParser.parse(utf8: data)
            XCTFail("Unexpectedly did not throw an error")
        } catch JSONParser.Error.endOfStreamUnexpected {
            return
        } catch {
            XCTFail("Incorrect error received.: \(error)")
        }
    }
    
    func testThatParserCompletesWithSingleZero() {
        guard let data = "0".data(using: String.Encoding.utf8) else {
            XCTFail("Cannot create data from string")
            return
        }

        do {
            _ = try JSONParser.parse(utf8: data)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserCompletesWithBOMAndSingleZero() {
        let hex: [UInt8] = [0xEF, 0xBB, 0xBF, 0x30]
        let data = Data(bytes: UnsafePointer<UInt8>(hex), count: hex.count)

        do {
            _ = try JSONParser.parse(utf8: data)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsNull() {
        let value = try! JSONParser.parse("null")
        XCTAssertEqual(value, JSON.null)
    }

    func testThatParserSkipsLeadingWhitespace() {
        let value = try! JSONParser.parse("   \t\r\nnull")
        XCTAssertEqual(value, JSON.null)
    }

    func testThatParserAllowsTrailingWhitespace() {
        let value = try! JSONParser.parse("null   ")
        XCTAssertEqual(value, JSON.null)
    }

    func testThatParserFailsWhenTrailingDataIsPresent() {
        do {
            _ = try JSONParser.parse("null   true")
        } catch JSONParser.Error.endOfStreamGarbage(let offset) {
            XCTAssertEqual(offset, 7)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testThatParserUnderstandsTrue() {
        let value = try! JSONParser.parse("true")
        XCTAssertEqual(value, JSON.Bool(true))
    }

    func testThatParserUnderstandsFalse() {
        let value = try! JSONParser.parse("false")
        XCTAssertEqual(value, JSON.Bool(false))
    }

    func testThatParserUnderstandsStringsWithoutEscapes() {
        let string = "a b c d 😀 x y z"
        let value = try! JSONParser.parse("\"\(string)\"")
        XCTAssertEqual(value, JSON.String(string))
    }

    func testThatParserUnderstandsStringsWithEscapedCharacters() {
        let expect = " \" \\ / \n \r \t \u{000c} \u{0008} "
        let value = try! JSONParser.parse("\" \\\" \\\\ \\/ \\n \\r \\t \\f \\b \"")
        XCTAssertEqual(value, JSON.String(expect))
    }

    func testThatParserUnderstandsStringsWithEscapedUnicode() {
        // try 1-, 2-, and 3-byte UTF8 sequences
        let expect = "\u{0060}\u{012a}\u{12AB}"
        let value = try! JSONParser.parse("\"\\u0060\\u012a\\u12AB\"")
        XCTAssertEqual(value, JSON.String(expect))
    }

    func testThatParserUnderstandsNumbers() {
        for (string, shouldBeInt) in [
            ("  0  ", 0),
            ("123", 123),
            ("  -20  ", -20),
        ] {
            do {
                let value = try JSONParser.parse(string).int()
                XCTAssertEqual(value, shouldBeInt)
            } catch {
                XCTFail("Unexpected error: \(error)")
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
            do {
                let value = try JSONParser.parse(string).double()
                XCTAssertEqualWithAccuracy(value, shouldBeDouble, accuracy: DBL_EPSILON)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testThatParserRejectsInvalidNumbers() {
        for (string, expectedError) in [
            ("012",   JSONParser.Error.endOfStreamGarbage(offset: 1)),
            ("0.1.2", JSONParser.Error.endOfStreamGarbage(offset: 3)),
            ("-.123", JSONParser.Error.numberSymbolMissingDigits(offset: 0)),
            (".123",  JSONParser.Error.valueInvalid(offset: 0, character: ".")),
            ("1.",    JSONParser.Error.endOfStreamUnexpected),
            ("1.0e",  JSONParser.Error.endOfStreamUnexpected),
            ("1.0e+", JSONParser.Error.endOfStreamUnexpected),
            ("1.0e-", JSONParser.Error.endOfStreamUnexpected),
            ("0e1",   JSONParser.Error.endOfStreamGarbage(offset: 1)),
        ] {
            do {
                _ = try JSONParser.parse(string)
            } catch let error as JSONParser.Error {
                XCTAssert(error == expectedError)
            } catch {
                XCTFail("Unexpected error \(error) in \(string)")
            }
        }
    }

    func testParserHandlingOfNumericOverflow() {
        for string in [
            // Int64.max + 1
            "9223372036854775808",

            // DBL_MAX is 1.7976931348623158e+308, so add 1 to least significant
            "1.7976931348623159e+308",

            // DBL_TRUE_MIN is 4.9406564584124654E-324, so try something smaller
            "4.9406564584124654E-325",
            ] {
                do {
                    let json = try JSONParser.parse(string)

                    // numbers overflow, but we should be able to get them out as strings
                    XCTAssertEqual(try? json.string(), string)
                } catch {
                    XCTFail("Unexpected error \(error)")
                }
        }
    }

    // This test should also be run on the iPhone 5 simulator to check 32-bit support.
    func testOverflowingIntResultsInStringWithNSJSONSerializationParser() {
        // In spite of writing this as an integer in the JSON, 64-bit NSJSONSerialization reads it in
        // as a double (CFNumberType() in makeJSON reports 13 aka kCFNumberDoubleType.
        //
        // Under 32-bit, though, it only reads in as a Double if you write it with a ".0" at the end,
        // otherwise it reads it in as a 4 = kCFNumberSInt64Type.
        let anyValueExceedingIntMax = UInt.max
        let jsonString = "{\"exceedsIntMax\": \(anyValueExceedingIntMax)}"

        let data = jsonString.data(using: String.Encoding.utf8)!
        guard let json = try? JSON(data: data, usingParser: JSONSerialization.self) else {
            XCTFail("Failed to even parse JSON: \(jsonString)")
            return
        }

        XCTAssertEqual(try? json.int("exceedsIntMax"), nil, "as int")
        XCTAssertEqual(try? json.double("exceedsIntMax"), Double(anyValueExceedingIntMax), "as double")
        XCTAssertEqual(try? json.string("exceedsIntMax"), nil, "as string")
    }

    // This test should also be run on the iPhone 5 simulator to check 32-bit support.
    func testOverflowingIntResultsInStringWithFreddyParser() {
        let anyValueExceedingIntMax = UInt.max
        let jsonString = "{\"exceedsIntMax\": \(anyValueExceedingIntMax)}"

        let data = jsonString.data(using: String.Encoding.utf8)!
        guard let json = try? JSON(data: data) else {
            XCTFail("Failed to even parse JSON: \(jsonString)")
            return
        }

        // The Freddy parser behaves consistently across architectures.
        XCTAssertEqual(try? json.int("exceedsIntMax"), nil, "as int")
        XCTAssertEqual(try? json.double("exceedsIntMax"), nil, "as double")
        XCTAssertEqual(try? json.string("exceedsIntMax"), anyValueExceedingIntMax.description, "as string")
    }

    // This was tripping a fatalError with the Freddy parser for 64-bit at one point:
    //     fatal error: floating point value can not be converted to Int because it is greater than Int.max
    // because we assumed the double would be in range of Int.
    func testReturnsNilWhenDoubleValueExceedingIntMaxIsAccessedAsInt() {
        let anyFloatingPointValueExceedingIntMax = Double(UInt(Int.max) + 1)
        let jsonString = "{\"exceedsIntMax\": \(anyFloatingPointValueExceedingIntMax)}"

        let data = jsonString.data(using: String.Encoding.utf8)!
        guard let json = try? JSON(data: data) else {
            XCTFail("Failed to even parse JSON: \(jsonString)")
            return
        }

        XCTAssertEqual(try? json.int("exceedsIntMax"), nil, "as int")
    }

    func testThatParserUnderstandsEmptyArrays() {
        let expect = JSON.Array([])
        for string in ["[]", "[  ]", "  [  ]  "] {
            let value = try! JSONParser.parse(string)
            XCTAssertEqual(value, expect)
        }
    }

    func testThatParserUnderstandsSingleItemArrays() {
        for (s, expect) in [
            (" [ null ] ", [JSON.null]),
            ("[true]", [JSON.Bool(true)]),
            ("[ [\"nested\"]]", [JSON.Array([.String("nested")])])
        ] {
            let value = try! JSONParser.parse(s)
            XCTAssertEqual(value, JSON.Array(expect))
        }
    }

    func testThatParserUnderstandsMultipleItemArrays() {
        for (string, expect) in [
            (" [ null   ,   \"foo\" ] ", [JSON.null, .String("foo")]),
            ("[true,true,false]", [JSON.Bool(true), .Bool(true), .Bool(false)]),
            ("[ [\"nested\",null], [[\"doubly\",true]]   ]",
                [JSON.Array([.String("nested"), .null]),
                 .Array([.Array([.String("doubly"), .Bool(true)])])])
        ] {
            let value = try! JSONParser.parse(string)
            XCTAssertEqual(value, JSON.Array(expect))
        }
    }

    func testThatParserUnderstandsEmptyObjects() {
        for string in ["{}", "  {   }  "] {
            let value = try! JSONParser.parse(string)
            XCTAssertEqual(value, JSON.Dictionary([:]))
        }
    }

    func testThatParserUnderstandsSingleItemObjects() {
        for (string, expect) in [
            ("{\"a\":\"b\"}", ["a":JSON.String("b")]),
            ("{  \"foo\"  :  [null]  }", ["foo": JSON.Array([.null])]),
            ("{  \"a\" : { \"b\": true }  }", ["a": JSON.Dictionary(["b":.Bool(true)])]),
        ] {
            let value = try! JSONParser.parse(string)
            XCTAssertEqual(value, JSON.Dictionary(expect))
        }
    }

    func testThatParserUnderstandsMultipleItemObjects() {
        for (string, expect) in [
            ("{\"a\":\"b\",\"c\":\"d\"}",
                ["a":JSON.String("b"),"c":.String("d")]),
            ("{  \"foo\"  :  [null]   ,   \"bar\":  true  }",
                ["foo": JSON.Array([.null]), "bar": .Bool(true)]),
            ("{  \"a\" : { \"b\": true }, \"c\": { \"x\" : true, \"y\": null }  }",
                ["a": JSON.Dictionary(["b":.Bool(true)]),
                 "c": .Dictionary(["x": .Bool(true), "y": .null])]),
        ] {
            let value = try! JSONParser.parse(string)
            XCTAssertEqual(value, JSON.Dictionary(expect))
        }
    }

    func testThatParserFailsForUnsupportedEncodings() {

        let unsupportedEncodings: [JSONEncodingDetector.Encoding] = [
            .utf16LE,
            .utf16BE,
            .utf32LE,
            .utf32BE
        ]
        let fixtures = JSONEncodingUTFTestFixtures()

        for encoding in unsupportedEncodings {
            let hex = fixtures.hexArray(encoding, includeBOM: false)
            let data = Data(bytes: UnsafePointer<UInt8>(hex), count: hex.count)
            let hexWithBOM = fixtures.hexArray(encoding, includeBOM: true)
            let dataWithBOM = Data(bytes: UnsafePointer<UInt8>(hexWithBOM), count: hexWithBOM.count)
            do {
                _ = try JSONParser.parse(utf8: data)
                _ = try JSONParser.parse(utf8: dataWithBOM)
                XCTFail("Unexpectedly did not throw an error")
            } catch JSONParser.Error.invalidUnicodeStreamEncoding(_) {
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
                let json = try JSONParser.parse(jsonString)
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
                let _ = try JSONParser.parse(invalidPairString)
                XCTFail("Unexpectedly parsed invalid surrogate pair")
            } catch JSONParser.Error.unicodeEscapeInvalid {
                // do nothing - this is the expected error
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
