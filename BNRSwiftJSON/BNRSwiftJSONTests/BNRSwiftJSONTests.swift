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
import Swift

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
    
    func testThatCollectResultsCanCreateArrayOfPeople() {
        let data = createData()
        
        let json = JSONValue.createJSONValueFrom(data!)
        let peopleArray = json.bind({ $0["people"] }).array.bind { collectResults(map($0, Person.createWithJSONValue)) }
        switch peopleArray {
        case .Success(let box):
            box.value.map { XCTAssertTrue($0.name != "", "There should be a name.") }
        case .Failure(let error):
            XCTAssertTrue(true == false, "There should be no failure.")
        }
    }

    func testThatSplitResultsCanCreateArrayOfPeople() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        
//        let peopleArray = json.bind({ $0["people"] }).array.map { splitResults(map($0, Person.createWithJSONValue)) }
        
        let peopleArray = json.bind({ $0["people"] }).array
        switch peopleArray {
        case .Success(let people):
            let results = splitResults(people.value.map({ Person.createWithJSONValue($0) }))
            XCTAssertTrue(results.successes.count != 0, "There should be successes.")
            XCTAssertTrue(results.failures.count == 0, "There should be no failures.")
        case .Failure(let error):
            XCTAssertTrue(false == true, "There should be no error.")
        }
    }
    
    func testSplitResultCanGatherPeopleInSuccesses() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let people = splitResult(json.bind({ $0["people"].array }), Person.createWithJSONValue)
        XCTAssertTrue(people.successes.count > 0, "There should be people in `successes`.")
        XCTAssertTrue(people.failures.count == 0, "There should be no errors in `failures`.")
    }
    
    func testSplitResultCanGatherErrorsInFailures() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let peopl = splitResult(json.bind({ $0["peopl"] }).array, Person.createWithJSONValue)
        XCTAssertTrue(peopl.successes.count == 0, "There should be no people in `successes`.")
        XCTAssertTrue(peopl.failures.count > 0, "There should be errors in `failures`.")
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
    
    func testThatJSONNullMatchesNullValue() {
        let data = createData()
        let json = JSONValue.createJSONValueFrom(data!)
        let key = json["key"]
        switch key {
        case .Success(let value):
            switch value {
            case .JSONNull:
                XCTAssert(true, "`value` should be `.JSONNull`.")
            default:
                XCTAssert(false, "`value` should be `.JSONNull`.")
            }
        case .Failure(let error):
            XCTAssert(false, "Shouldn't be an error.")
        }
    }
    
    func testThatYouCanAccessNestedKeys() {
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
    
}
