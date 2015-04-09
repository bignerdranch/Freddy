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
import Result

class BNRSwiftJSONTests: XCTestCase {
    
    func testThatJSONCanCreateInstanceWithData() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        switch json {
        case .Success(let b):
            XCTAssert(true, "There should be a `JSON` in the `box`.")
        case .Failure(let error):
            XCTAssert(false, "There should be no error in parsing the sample JSON data.")
        }
    }
    
    func testThatJSONCanCreatePeople() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let peopleArray = json["people"].array
        switch peopleArray {
        case .Success(let people):
            for person in people.value {
                let per = Person.createWithJSON(person)
                switch per {
                case .Success(let p):
                    XCTAssertTrue(p.value.name != "", "People should have names.")
                case .Failure(let error):
                    XCTAssert(false, "There should be no `error`.")
                }
            }
        case .Failure(let error):
            XCTAssert(false, "There should be no error.")
        }
    }
    
    func testThatCollectResultsCanCreateArrayOfPeople() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let peopleArray = json.bind { $0["people"] }.array.bind { collectResults(map($0, Person.createWithJSON)) }
        switch peopleArray {
        case .Success(let box):
            box.value.map { XCTAssertTrue($0.name != "", "There should be a name.") }
        case .Failure(let error):
            XCTAssert(false, "There should be no failure.")
        }
    }

    func testThatSplitResultsCanCreateArrayOfPeople() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let peopleArray = json.bind { $0["people"] }.array
        switch peopleArray {
        case .Success(let people):
            let (successes, failures) = partitionResults(people.value.map { Person.createWithJSON($0) })
            XCTAssertTrue(successes.count != 0, "There should be successes.")
            XCTAssertTrue(failures.count == 0, "There should be no failures.")
        case .Failure(let error):
            XCTAssert(false, "There should be no error.")
        }
    }
    
    func testSplitResultCanGatherPeopleInSuccesses() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let people = splitResult(json["people"].array, Person.createWithJSON)
        XCTAssertTrue(people.successes.count > 0, "There should be people in `successes`.")
        XCTAssertTrue(people.failures.count == 0, "There should be no errors in `failures`.")
    }
    
    func testSplitResultCanGatherErrorsInFailures() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let peopl = splitResult(json["peopl"].array, Person.createWithJSON)
        XCTAssertTrue(peopl.successes.count == 0, "There should be no people in `successes`.")
        XCTAssertTrue(peopl.failures.count > 0, "There should be errors in `failures`.")
    }
    
    func testThatSubscriptingJSONWorksForTopLevelObject() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let success = json["success"].bool
        switch success {
        case .Success(let s):
            XCTAssertTrue(s.value == true, "There should be `success`.")
        case .Failure(let error):
            XCTAssert(false, "There should be no error: \(error)")
        }
    }
    
    func testThatJSONNullMatchesNullValue() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let key = json["key"]
        switch key {
        case .Success(let value):
            switch value {
            case .Null:
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
        let json = JSON.createJSONFrom(data!)
        let zips = json["states"]["Georgia"].array
        switch zips {
        case .Success(let zps):
            for z in zps.value {
                XCTAssertNotNil(z.int, "The `Int` should not be `nil`.")
            }
        case .Failure(let error):
            XCTAssert(false, "There should be no `error`.")
        }
    }

    func testJSONSubscriptWithInt() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let matt = json["people"][0]["name"].string
        switch matt {
        case .Success(let n):
            XCTAssertEqual(n.value, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
        case .Failure(let error):
            XCTAssert(false, "There should be no error: \(error)")
        }
    }

    func testJSONErrorKeyNotFound() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let peopl = json["peopl"]
        switch peopl {
        case .Success(let ppl):
            XCTAssert(false, "There should be no people.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.KeyNotFound.rawValue, "The error should be due to the key not being found.")
        }
    }
    
    func testJSONErrorIndexOutOfBounds() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let person = json["people"][4]
        switch person {
        case .Success(let p):
            XCTAssert(false, "There should be no person at index 4.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.IndexOutOfBounds.rawValue, "The error should be due to the index being out of bounds.")
        }
    }
    
    func testJSONErrorTypeNotConvertible() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let matt = json["people"][0]["name"].number
        switch matt {
        case .Success(let name):
            XCTAssert(false, "The `name` should not be convertible to `number`.")
        case .Failure(let errorType):
            let error = errorType as! NSError
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.TypeNotConvertible.rawValue, "The error should be due to `name` not being convertible to `number`.")
        }
    }
    
    func testJSONErrorUnexpectedType() {
        let data = createData()
        let json = JSON.createJSONFrom(data!)
        let matt = json["people"]["name"]
        switch matt {
        case .Success(let name):
            XCTAssert(false, "The `name` key should not be availabe as a subscript for the `Array` `people`.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.UnexpectedType.rawValue, "The `people` `Array` is not subscriptable with `String`s.")
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
