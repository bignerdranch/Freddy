//
//  JSONBenchmark.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

import XCTest

#if os(OSX)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

import Argo
import BNRSwiftJSON
import Result

class JSONBenchmark: XCTestCase {

    private var jsonURL: NSURL!
    private var jsonData: NSData!

    override func setUp() {
        super.setUp()

        jsonURL = NSBundle(forClass: JSONBenchmark.self).URLForResource("AllSetsArray", withExtension: "json")
        XCTAssert(jsonURL != nil)

        jsonData = NSData(contentsOfURL: jsonURL, options: .DataReadingMappedIfSafe, error: nil)
        XCTAssert(jsonData != nil)
    }

    func testCocoaDeserializeBaseline() {
        measureBlock {
            var error: NSError?
            if NSJSONSerialization.JSONObjectWithData(self.jsonData, options: nil, error: &error) == nil {
                XCTFail("JSON parsing failed with error \(error)")
            }
        }
    }

    func testBNRSwiftDeserialize() {
        measureBlock {
            let json = JSONFromUTF8Data(self.jsonData)
            XCTAssert(json.isSuccess, "JSON failed to parse")
        }

    }

    func testFullCocoaDeserialize() {
        measureBlock {
            var error: NSError?
            if let cocoaJSON = NSJSONSerialization.JSONObjectWithData(self.jsonData, options: nil, error: &error) as? [AnyObject] {
                if let objects = CardSetObjC.cardSetsFromDictionaries(cocoaJSON) {
                    XCTAssert(objects.count == cocoaJSON.count, "Failed to convert all sets")
                } else {
                    XCTFail("Failed to turn Cocoa dictionaries into model objects")
                }
            } else {
                XCTFail("JSON parsing failed with error \(error)")
            }
        }
    }

    func testFullBNRSwiftDeserialize() {
        measureBlock {
            let json = JSONFromUTF8Data(self.jsonData)
            XCTAssert(json.isSuccess, "JSON failed to parse")

            // this should be almost one-liner:
            //     json.bind { collectAllSuccesses(lazy($0).map(CardSet.createWithJSON)) }
            // I consider this an API deficiency - the parser should use
            // JSONResult or JSON should be a sequence. (GH #26)

            if let array = json.successValue?.array {
                let objects = collectAllSuccesses(lazy(array).map(CardSet.createWithJSON))
                if let objects = objects.successValue {
                    XCTAssert(objects.count == json.successValue!.array!.count, "Failed to convert all sets")
                } else {
                    XCTFail("Failed to turn Cocoa dictionaries into model objects: \(objects.failureValue!)")
                }
            } else {
                XCTFail("Failed to turn decode JSON: \(json.failureValue)")
            }
        }
    }

    // ~ 107 MB  peak memory usage, very... very long time
    func testFullArgoDeserialize() {
        measureBlock {
            var error: NSError?
            if let cocoaJSON = NSJSONSerialization.JSONObjectWithData(self.jsonData, options: nil, error: &error) as? [AnyObject] {
                let decoded = decode(cocoaJSON) as Decoded<[CardSet]>
                switch decoded {
                case .Success(let box):
                    let objects = box.value
                    XCTAssert(objects.count == cocoaJSON.count, "Failed to convert all sets")
                case .TypeMismatch(let mismatch):
                    XCTFail("Type mismatch: \(mismatch)")
                case .MissingKey(let missing):
                    XCTFail("Missing key: \(missing)")
                }
            } else {
                XCTFail("JSON parsing failed with error \(error)")
            }
        }
    }

}
