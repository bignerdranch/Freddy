//
//  JSONEncodingDetectorTests.swift
//  Freddy
//
//  Created by Robert Edwards on 1/27/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
@testable import Freddy

class JSONEncodingDetectorTests: XCTestCase {

    let fixtures = JSONEncodingUTFTestFixtures()

    // MARK: - UTF16

    func testUTF16LittleEndianDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF16LE, includeBOM: false))
        XCTAssertEqual(encoding, NSUTF16LittleEndianStringEncoding)
    }

    func testUTF16LittleEndianWithBOMDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF16LE, includeBOM: true))
        XCTAssertEqual(encoding, NSUTF16LittleEndianStringEncoding)
    }

    func testUTF16BigEndianDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF16BE, includeBOM: false))
        XCTAssertEqual(encoding, NSUTF16BigEndianStringEncoding)
    }

    func testUTF16BigEndianWithBOMDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF16BE, includeBOM: true))
        XCTAssertEqual(encoding, NSUTF16BigEndianStringEncoding)
    }

    // MARK: - UTF32

    func testUTF32LittleEndianDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF32LE, includeBOM: false))
        XCTAssertEqual(encoding, NSUTF32LittleEndianStringEncoding)
    }

    func testUTF32LittleEndianWithBOMDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF32LE, includeBOM: true))
        XCTAssertEqual(encoding, NSUTF32LittleEndianStringEncoding)
    }

    func testUTF32BigEndianDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF32BE, includeBOM: false))
        XCTAssertEqual(encoding, NSUTF32BigEndianStringEncoding)
    }

    func testUTF32BigEndianWithBOMDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF32BE, includeBOM: true))
        XCTAssertEqual(encoding, NSUTF32BigEndianStringEncoding)
    }

    // MARK: - UTF8

    func testUTF8Detection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF8, includeBOM: false))
        XCTAssertEqual(encoding, NSUTF8StringEncoding)
    }

    func testUTF8WithBOMDetection() {
        let encoding = JSONEncodingDetector.detectEncoding(fixtures.prefixSlice(.UTF8, includeBOM: true))
        XCTAssertEqual(encoding, NSUTF8StringEncoding)
    }
}

struct JSONEncodingUTFTestFixtures {

    enum Encoding {
        case UTF8
        case UTF16LE
        case UTF16BE
        case UTF32LE
        case UTF32BE
    }

    func hexArray(encoding: Encoding, includeBOM: Bool) -> [UInt8] {
        switch encoding {
        case Encoding.UTF8:
            return includeBOM ? utf8BOM + utf8Hex : utf8Hex
        case Encoding.UTF16LE:
            return includeBOM ? utf16LEBOM + utf16LEHex : utf16LEHex
        case Encoding.UTF16BE:
            return includeBOM ? utf16BEBOM + utf16BEHex : utf16BEHex
        case Encoding.UTF32LE:
            return includeBOM ? utf32LEBOM + utf32LEHex : utf32LEHex
        case Encoding.UTF32BE:
            return includeBOM ? utf32BEBOM + utf32BEHex : utf32BEHex
        }
    }

    func prefixSlice(encoding: Encoding, includeBOM: Bool) -> Slice<UnsafeBufferPointer<UInt8>> {
        let array = hexArray(encoding, includeBOM: includeBOM)
        let buffer = UnsafeBufferPointer<UInt8>(start: array, count: array.count)
        let prefix = buffer.prefix(4)
        return prefix
    }

    // MARK: - UTF16

    // String literal representation "{\"u\":16}"
    private let utf16LEHex: [UInt8] = [
        0x7B, 0x0,
        0x22, 0x0,
        0x75, 0x0,
        0x22, 0x0,
        0x3A, 0x0,
        0x31, 0x0,
        0x36, 0x0,
        0x7D, 0x0]

    private let utf16LEBOM: [UInt8] = [
        0xFF,
        0xFE
    ]

    // String literal representation "{\"u\":16}"
    private let utf16BEHex: [UInt8] = [
        0x00, 0x7B,
        0x00, 0x22,
        0x00, 0x75,
        0x00, 0x22,
        0x00, 0x3A,
        0x00, 0x31,
        0x00, 0x36,
        0x00, 0x7D]

    private let utf16BEBOM: [UInt8] = [
        0xFE,
        0xFF
    ]

    // MARK: - UTF32

    // String literal representation "{\"u\":32}"
    private let utf32LEHex: [UInt8] = [
        0x7B, 0x00, 0x00, 0x00,
        0x22, 0x00, 0x00, 0x00,
        0x75, 0x00, 0x00, 0x00,
        0x22, 0x00, 0x00, 0x00,
        0x3A, 0x00, 0x00, 0x00,
        0x33, 0x00, 0x00, 0x00,
        0x32, 0x00, 0x00, 0x00,
        0x7D, 0x00, 0x00, 0x00]

    private let utf32LEBOM: [UInt8] = [
        0xFF,
        0xFE,
        0x00,
        0x00
    ]

    // String literal representation "{\"u\":32}"
    private let utf32BEHex: [UInt8] = [
        0x00, 0x00, 0x00, 0x7B,
        0x00, 0x00, 0x00, 0x22,
        0x00, 0x00, 0x00, 0x75,
        0x00, 0x00, 0x00, 0x22,
        0x00, 0x00, 0x00, 0x3A,
        0x00, 0x00, 0x00, 0x33,
        0x00, 0x00, 0x00, 0x32,
        0x00, 0x00, 0x00, 0x7D]

    private let utf32BEBOM: [UInt8] = [
        0x00,
        0x00,
        0xFE,
        0xFF
    ]

    // MARK: - UTF8

    // String literal representation "{\"u\":8}"
    private let utf8Hex: [UInt8] = [
        0x7B,
        0x22,
        0x75,
        0x22,
        0x3A,
        0x38,
        0x7D]

    private let utf8BOM: [UInt8] = [
        0xEF,
        0xBB,
        0xBF
    ]
}
