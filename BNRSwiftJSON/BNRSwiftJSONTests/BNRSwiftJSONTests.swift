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
        switch json {
        case .Success(let b):
            XCTAssertTrue(true == true, "There should be a `JSONValue` in the `box`.")
        case .Failure(let error):
            XCTAssertTrue(true == false, "There should be no error in parsing the sample JSON data.")
        }
    }
    
    func testThatJSONValueCanCreateArrayOfPeople() {
        let data = createData()
        
        let json = JSONValue.createJSONValueFrom(data!)
        let peopleArray = json.bind({ $0["people"] }).array.bind { self.collectResults(map($0, Person.createWithJSONValue)) }
        
        switch peopleArray {
        case .Success(let box):
            box.value.map { XCTAssertTrue($0.name != "", "There should be a name.") }
        case .Failure(let error):
            XCTAssertTrue(true == false, "There should be no failure.")
        }
    }
    
    func testThatJSONValueCanCreatePeople() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let peopleArray = json["people"].array
        switch peopleArray {
        case .Success(let people):
            for person in people.value {
                let per = Person.createWithJSONValue(person)
                switch per {
                case .Success(let p):
                    XCTAssertTrue(p.value.name != "", "People should have names.")
                case .Failure(let error):
                    XCTAssertTrue(true == false, "There should be no `error`.")
                }
            }
        case .Failure(let error):
            XCTAssertTrue(false == true, "There should be no error.")
        }
    }
    
    func testThatSubscriptingJSONValueWorksForTopLevelObject() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let success = json["success"].bool
        switch success {
        case .Success(let s):
            XCTAssertTrue(s.value == true, "There should be `success`.")
        case .Failure(let error):
            XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
        }
    }
    
    func testThatYouCanAssessNestedKeys() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let zips = json["states"]["Georgia"].array
        switch zips {
        case .Success(let zps):
            for z in zps.value {
                XCTAssertNotNil(z.int, "The `Int` should not be `nil`.")
            }
        case .Failure(let error):
            XCTAssertTrue(true == false, "There should be no `error`.")
        }
    }

    func testJSONValueSubscriptWithInt() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let matt = json["people"][0]["name"].string
        switch matt {
        case .Success(let n):
            XCTAssertEqual(n.value, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
        case .Failure(let error):
            XCTAssertFalse(true == false, "There should be no error: \(error.localizedFailureReason)")
        }
    }

    func testJSONValueErrorKeyNotFound() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let peopl = json["peopl"]
        switch peopl {
        case .Success(let ppl):
            XCTAssertTrue(true == false, "There should be no people.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.KeyNotFound.rawValue, "The error should be due to the key not being found.")
        }
    }
    
    func testJSONValueErrorIndexOutOfBounds() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let person = json["people"][4]
        switch person {
        case .Success(let p):
            XCTAssertTrue(true == false, "There should be no person at index 4.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.IndexOutOfBounds.rawValue, "The error should be due to the index being out of bounds.")
        }
    }
    
    func testJSONValueErrorTypeNotConvertible() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let matt = json["people"][0]["name"].number
        switch matt {
        case .Success(let name):
            XCTAssertTrue(true == false, "The `name` should not be convertible to `number`.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible.rawValue, "The error should be due to `name` not being convertible to `number`.")
        }
    }
    
    func testJSONValueErrorUnexpectedType() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let matt = json["people"]["name"]
        switch matt {
        case .Success(let name):
            XCTAssertTrue(true == false, "The `name` key should not be availabe as a subscript for the `Array` `people`.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSONValue.BNRSwiftJSONErrorCode.UnexpectedType.rawValue, "The `people` `Array` is not subscriptable with `String`s.")
        }
    }
    
    func createData() -> NSData? {
        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        let path = testBundle.pathForResource("sample", ofType: "JSON")
        
        if let p = path, u = NSURL(fileURLWithPath: p) {
            return NSData(contentsOfURL: u)
        }
        
        return nil
    }
    
    func collectResults<T>(results: [Result<T>]) -> Result<[T]> {
        var successes = [T]()
        for result in results {
            switch result {
            case .Success(let res):
                successes.append(res.value)
            case .Failure(let error):
                return .Failure(error)
            }
        }
        return .Success(Box(successes))
    }
    
}
