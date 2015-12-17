//
//  JSONBenchmark.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

import XCTest
import BNRSwiftJSON

private enum ErrorFromObjCModel: ErrorType {
    case FailedToDecode
}

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
    
    private func measureWithoutRR<T>(body: () throws -> T, assertions: (T -> ())?) {
        measureMetrics(self.dynamicType.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            var value: T!
            
            self.startMeasuring()
            value = try? body()
            self.stopMeasuring()
            
            XCTAssertNotNil(value)
            assertions?(value)
            
            value = nil
        }
    }

    func testJSONDeserializeCocoa() {
        measureWithoutRR({
            try NSJSONSerialization.JSONObjectWithData(self.jsonData, options: [])
        }, assertions: nil)
    }

    func testJSONDeserializeCustom() {
        measureWithoutRR({
            try JSON(data: self.jsonData, usingParser: JSONParser.self)
        }, assertions: nil)
    }

    func testJSONDeserializeCustomViaCocoa() {
        measureWithoutRR({
            try JSON(data: self.jsonData, usingParser: NSJSONSerialization.self)
        }, assertions: nil)
    }

    func testJSONDeserializeToCocoaModel() {
        measureWithoutRR({ () throws -> ([CardSetObjC], Int) in
            let cocoaJSON = try NSJSONSerialization.JSONObjectWithData(self.jsonData, options: []) as! [[String: AnyObject]]
            guard let objects = CardSetObjC.cardSetsFromDictionaries(cocoaJSON) else {
                throw ErrorFromObjCModel.FailedToDecode
            }
            return (objects, cocoaJSON.count)
        }, assertions: {
            XCTAssertEqual($0.0.count, $0.1, "Failed to convert all sets")
        })
    }

    func testJSONDeserializeToModel() {
        measureWithoutRR({ () throws -> ([CardSet], Int) in
            let json = try JSON(data: self.jsonData, usingParser: JSONParser.self)
            let expectedCount = try json.array().count
            let objects = try json.arrayOf(type: CardSet.self)
            return (objects, expectedCount)
        }, assertions: {
            XCTAssertEqual($0.0.count, $0.1, "Failed to convert all sets")
        })
    }

}
