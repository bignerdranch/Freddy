//
//  JSONBenchmark.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

import XCTest
import BNRSwiftJSON

class JSONBenchmark: XCTestCase {

    private var jsonData: NSData!

    override func setUp() {
        super.setUp()

        let testBundle = NSBundle(forClass: JSONBenchmark.self)
        guard let data = testBundle.URLForResource("AllSetsArray", withExtension: "json").flatMap(NSData.init) else {
            XCTFail("Could not read stress test data from test bundle")
            return
        }

        jsonData = data
    }

    func testJSONDeserializeCocoa() {
        measureBlock {
            _ = try! NSJSONSerialization.JSONObjectWithData(self.jsonData, options: [])
        }
    }

    func testJSONDeserializeCustom() {
        measureBlock {
            _ = try! JSON(data: self.jsonData, usingParser: JSONParser.self)
        }
    }

    func testJSONDeserializeCustomViaCocoa() {
        measureBlock {
            _ = try! JSON(data: self.jsonData, usingParser: NSJSONSerialization.self)
        }
    }

    func testJSONDeserializeToCocoaModel() {
        measureBlock {
            let cocoaJSON = try! NSJSONSerialization.JSONObjectWithData(self.jsonData, options: []) as! [[String: AnyObject]]
            let objects = CardSetObjC.cardSetsFromDictionaries(cocoaJSON)
            XCTAssertEqual(objects?.count, cocoaJSON.count, "Failed to convert all sets")
        }
    }

    func testJSONDeserializeToModel() {
        measureBlock {
            let json = try! JSON(data: self.jsonData, usingParser: JSONParser.self)
            let expectedCount = try! json.array().count
            let objects = try? json.arrayOf(type: CardSet.self)
            XCTAssertEqual(objects?.count, expectedCount, "Failed to convert all sets")
        }
    }

}
