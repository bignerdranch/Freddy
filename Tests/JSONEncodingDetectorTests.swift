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
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf16LE
        let encoding = fixtures.withPrefixSlice(expectedEncoding, includeBOM: false, body: JSONEncodingDetector.detectEncoding).encoding
        XCTAssertEqual(encoding, expectedEncoding)
    }

    func testUTF16LittleEndianWithBOMDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf16LE
        let encodingPrefixInformation = fixtures.withPrefixSlice(.utf16LE, includeBOM: true, body: JSONEncodingDetector.detectEncoding)
        // TODO: Swift 2.2 replace with a single XCTAssertEqual for the `ByteStreamPrefixInformation` tuple
        XCTAssertEqual(encodingPrefixInformation.encoding, expectedEncoding)
        XCTAssertEqual(encodingPrefixInformation.byteOrderMarkLength, 2)
    }

    func testUTF16BigEndianDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf16BE
        let encoding = fixtures.withPrefixSlice(.utf16BE, includeBOM: false, body: JSONEncodingDetector.detectEncoding).encoding
        XCTAssertEqual(encoding, expectedEncoding)
    }

    func testUTF16BigEndianWithBOMDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf16BE
        let encodingPrefixInformation = fixtures.withPrefixSlice(.utf16BE, includeBOM: true, body: JSONEncodingDetector.detectEncoding)
        // TODO: Swift 2.2 replace with a single XCTAssertEqual for the `ByteStreamPrefixInformation` tuple
        XCTAssertEqual(encodingPrefixInformation.encoding, expectedEncoding)
        XCTAssertEqual(encodingPrefixInformation.byteOrderMarkLength, 2)
    }

    // MARK: - UTF32

    func testUTF32LittleEndianDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf32LE
        let encoding = fixtures.withPrefixSlice(expectedEncoding, includeBOM: false, body: JSONEncodingDetector.detectEncoding).encoding
        XCTAssertEqual(encoding, expectedEncoding)
    }

    func testUTF32LittleEndianWithBOMDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf32LE
        let encodingPrefixInformation = fixtures.withPrefixSlice(.utf32LE, includeBOM: true, body: JSONEncodingDetector.detectEncoding)
        // TODO: Swift 2.2 replace with a single XCTAssertEqual for the `ByteStreamPrefixInformation` tuple
        XCTAssertEqual(encodingPrefixInformation.encoding, expectedEncoding)
        XCTAssertEqual(encodingPrefixInformation.byteOrderMarkLength, 4)
    }

    func testUTF32BigEndianDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf32BE
        let encoding = fixtures.withPrefixSlice(.utf32BE, includeBOM: false, body: JSONEncodingDetector.detectEncoding).encoding
        XCTAssertEqual(encoding, expectedEncoding)
    }

    func testUTF32BigEndianWithBOMDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf32BE
        let encodingPrefixInformation = fixtures.withPrefixSlice(.utf32BE, includeBOM: true, body: JSONEncodingDetector.detectEncoding)
        // TODO: Swift 2.2 replace with a single XCTAssertEqual for the `ByteStreamPrefixInformation` tuple
        XCTAssertEqual(encodingPrefixInformation.encoding, expectedEncoding)
        XCTAssertEqual(encodingPrefixInformation.byteOrderMarkLength,4)
    }

    // MARK: - UTF8

    func testUTF8Detection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf8
        let encoding = fixtures.withPrefixSlice(.utf8, includeBOM: false, body: JSONEncodingDetector.detectEncoding).encoding
        XCTAssertEqual(encoding, expectedEncoding)
    }

    func testUTF8WithBOMDetection() {
        let expectedEncoding: JSONEncodingDetector.Encoding = .utf8
        let encodingPrefixInformation = fixtures.withPrefixSlice(.utf8, includeBOM: true, body: JSONEncodingDetector.detectEncoding)
        // TODO: Swift 2.2 replace with a single XCTAssertEqual for the `ByteStreamPrefixInformation` tuple
        XCTAssertEqual(encodingPrefixInformation.encoding, expectedEncoding)
        XCTAssertEqual(encodingPrefixInformation.byteOrderMarkLength, 3)
    }
}

struct JSONEncodingUTFTestFixtures {

    func hexArray(_ encoding: JSONEncodingDetector.Encoding, includeBOM: Bool) -> [UInt8] {
        switch encoding {
        case .utf8:
            return includeBOM ? utf8BOM + utf8Hex : utf8Hex
        case .utf16LE:
            return includeBOM ? utf16LEBOM + utf16LEHex : utf16LEHex
        case .utf16BE:
            return includeBOM ? utf16BEBOM + utf16BEHex : utf16BEHex
        case .utf32LE:
            return includeBOM ? utf32LEBOM + utf32LEHex : utf32LEHex
        case .utf32BE:
            return includeBOM ? utf32BEBOM + utf32BEHex : utf32BEHex
        }
    }

    func withPrefixSlice<R>(_ encoding: JSONEncodingDetector.Encoding, includeBOM: Bool, body: (RandomAccessSlice<UnsafeBufferPointer<UInt8>>) throws -> R) rethrows -> R {
        let array = hexArray(encoding, includeBOM: includeBOM)
        return try array.withUnsafeBufferPointer {
            try body($0.prefix(4))
        }
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
