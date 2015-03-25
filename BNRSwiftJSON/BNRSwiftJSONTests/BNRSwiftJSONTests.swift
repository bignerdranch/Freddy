//
//  BNRSwiftJSONTests.swift
//  BNRSwiftJSONTests
//
//  Created by Matthew D. Mathias on 3/25/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import UIKit
import XCTest
import BNRSwiftJSON

class BNRSwiftJSONTests: XCTestCase {
    
    func testThatJSONValueCanCreateInstanceWithData() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        XCTAssert(json != nil, "JSONValue should not be nil.")
    }
    
    func testThatJSONValueCanCreateArrayOfPeople() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let people = json?["people"].array {
            switch people {
            case .Success(let ppl):
                let mappedPeople = map(ppl.value) { Person.createWithJSONValue($0) }
                for boxedPerson in mappedPeople {
                    switch boxedPerson {
                    case .Success(let person):
                        XCTAssertTrue(person.value.name != "", "Every person should not be `nil`.")
                    case .Failure(let error):
                        XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
                    }
                }
            case .Failure(let error):
                XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
            }
        }
    }
    
    func testThatSubscriptingJSONValueWorksForTopLevelObject() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let success = json?["success"].bool {
            switch success {
            case .Success(let s):
                XCTAssertTrue(s.value == true, "There should be `success`.")
            case .Failure(let error):
                XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
            }
        }
    }
    
    func testThatYouCanAccessNestedKeys() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let zips = json?["states"]["Georgia"].array {
            switch zips {
            case .Success(let zps):
                for z in zps.value {
                    XCTAssertNotNil(z.int, "There should be an area of zip codes.")
                }
            case .Failure(let error):
                XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
            }
        }
    }
    
    func testJSONValueSubscriptWithInt() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let matt = json?["people"][0]["name"].string {
            switch matt {
            case .Success(let n):
                XCTAssertEqual(n.value, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
            case .Failure(let error):
                XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
            }
        }
    }
    
    func testJSONValueErrorKeyNotFound() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let peopl = json?["peopl"] {
            switch peopl {
            case .Success(let ppl):
                XCTAssertTrue(true == false, "There should be no people.")
            case .Failure(let error):
                XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.KeyNotFound.rawValue, "The error should be due to the key not being found.")
            }
        }
    }
    
    func testJSONValueErrorIndexOutOfBounds() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let person = json?["people"][4] {
            switch person {
            case .Success(let p):
                XCTAssertTrue(true == false, "There should be no person at index 4.")
            case .Failure(let error):
                XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.IndexOutOfBounds.rawValue, "The error should be due to the index being out of bounds.")
            }
        }
    }
    
    func testJSONValueErrorTypeNotConvertible() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let matt = json?["people"][0]["name"].number {
            switch matt {
            case .Success(let name):
                XCTAssertTrue(true == false, "The `name` should not be convertible to `number`.")
            case .Failure(let error):
                XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible.rawValue, "The error should be due to `name` not being convertible to `number`.")
            }
        }
    }
    
    func testJSONValueErrorUnexpectedType() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        if let matt = json?["people"]["name"] {
            switch matt {
            case .Success(let name):
                XCTAssertTrue(true == false, "The `name` key should not be availabe as a subscript for the `Array` `people`.")
            case .Failure(let error):
                XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.UnexpectedType.rawValue, "The `people` `Array` is not subscriptable with `String`s.")
            }
        }
    }
    
    func createData() -> NSData? {
        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        let path = testBundle.pathForResource("sample", ofType: "JSON")
        let url = NSURL(fileURLWithPath: path!)
        let data = NSData(contentsOfURL: url!)
        return data
    }
    
}
