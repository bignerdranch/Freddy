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
    
    lazy var data: NSData? = {
        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        let path = testBundle.pathForResource("sample", ofType: "JSON")
        
        if let p = path, u = NSURL(fileURLWithPath: p) {
            return NSData(contentsOfURL: u)
        }
        
        return nil
    }()
    
    func testThatJSONCanCreateInstanceWithData() {
        let json = JSON.createJSONFrom(data!)
        XCTAssertTrue(json.isSuccess, "The sample JSON data should be parsed successfully.")
    }
    
    func testThatJSONCanBeSerialized() {
        let json = JSON.createJSONFrom(data!)
        let serializedJSONData = json.serialize()
        switch serializedJSONData {
        case .Success(let data):
            XCTAssertNotNil(data, "JSON should be serializable.")
        case .Failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testThatJSONSerializationMakesEqualJSON() {
        let json = JSON.createJSONFrom(data!)
        let serializedJSONData = json.serialize()
        switch serializedJSONData {
        case .Success(let data):
            let serialJSON = JSON.createJSONFrom(data.value)
            XCTAssertEqual(json, serialJSON, "The JSON values should be equal.")
        case .Failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testThatJSONCanCreatePeople() {
        let json = JSON.createJSONFrom(data!)
        let peopleArray = json["people"].array
        switch peopleArray {
        case .Success(let people):
            for person in people.value {
                let per = Person.createWithJSON(person)
                switch per {
                case .Success(let p):
                    XCTAssertNotEqual(p.value.name, "", "People should have names.")
                case .Failure(let error):
                    XCTFail("There should be no `error`.")
                }
            }
        case .Failure(let error):
            XCTFail("There should be no error.")
        }
    }
    
    func testThatCollectResultsCanCreateArrayOfPeople() {
        let json = JSON.createJSONFrom(data!)
        let peopleArray = json["people"].array.bind { collectResults(map($0, Person.createWithJSON)) }
        switch peopleArray {
        case .Success(let box):
            for person in box.value {
                XCTAssertNotEqual(person.name, "", "There should be a name.")
            }
        case .Failure(let error):
            XCTFail("There should be no failure.")
        }
    }

    func testThatSplitResultsCanCreateArrayOfPeople() {
        let json = JSON.createJSONFrom(data!)
        let peopleArray = json["people"].array
        switch peopleArray {
        case .Success(let people):
            let (successes, failures) = partitionResults(people.value.map { Person.createWithJSON($0) })
            XCTAssertNotEqual(successes.count, 0, "There should be successes.")
            XCTAssertEqual(failures.count, 0, "There should be no failures.")
        case .Failure(let error):
            XCTFail("There should be no error.")
        }
    }
    
    func testSplitResultCanGatherPeopleInSuccesses() {
        let json = JSON.createJSONFrom(data!)
        let people = splitResult(json["people"].array, Person.createWithJSON)
        XCTAssertGreaterThan(people.successes.count, 0, "There should be people in `successes`.")
        XCTAssertEqual(people.failures.count, 0, "There should be no errors in `failures`.")
    }
    
    func testSplitResultCanGatherErrorsInFailures() {
        let json = JSON.createJSONFrom(data!)
        let peopl = splitResult(json["peopl"].array, Person.createWithJSON)
        XCTAssertEqual(peopl.successes.count, 0, "There should be no people in `successes`.")
        XCTAssertGreaterThan(peopl.failures.count, 0, "There should be errors in `failures`.")
    }
    
    func testThatSubscriptingJSONWorksForTopLevelObject() {
        let json = JSON.createJSONFrom(data!)
        let success = json["success"].bool
        switch success {
        case .Success(let s):
            XCTAssertTrue(s.value, "There should be `success`.")
        case .Failure(let error):
            XCTFail("There should be no error: \(error)")
        }
    }
    
    func testThatJSONNullMatchesNullValue() {
        let json = JSON.createJSONFrom(data!)
        let key = json["key"].null

        switch key {
        case .Success:
            break
        case .Failure(let error):
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testThatYouCanAccessNestedKeys() {
        let json = JSON.createJSONFrom(data!)
        let zips = json["states"]["Georgia"].array
        switch zips {
        case .Success(let zps):
            for z in zps.value {
                XCTAssertNotNil(z.int, "The `Int` should not be `nil`.")
            }
        case .Failure(let error):
            XCTFail("There should be no `error`.")
        }
    }

    func testJSONSubscriptWithInt() {
        let json = JSON.createJSONFrom(data!)
        let matt = json["people"][0]["name"].string
        switch matt {
        case .Success(let n):
            XCTAssertEqual(n.value, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
        case .Failure(let error):
            XCTFail("There should be no error: \(error)")
        }
    }

    func testJSONErrorKeyNotFound() {
        let json = JSON.createJSONFrom(data!)
        let peopl = json["peopl"].array
        switch peopl {
        case .Success:
            XCTFail("There should be no people.")
        case .Failure(let errorType):
            let error = errorType as! NSError
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.KeyNotFound.rawValue, "The error should be due to the key not being found.")
        }
    }
    
    func testJSONErrorIndexOutOfBounds() {
        let json = JSON.createJSONFrom(data!)
        let person = json["people"][4].dictionary
        switch person {
        case .Success:
            XCTFail("There should be no person at index 4.")
        case .Failure(let errorType):
            let error = errorType as! NSError
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.IndexOutOfBounds.rawValue, "The error should be due to the index being out of bounds.")
        }
    }
    
    func testJSONErrorTypeNotConvertible() {
        let json = JSON.createJSONFrom(data!)
        let matt = json["people"][0]["name"].number
        switch matt {
        case .Success(let name):
            XCTFail("The `name` should not be convertible to `number`.")
        case .Failure(let errorType):
            let error = errorType as! NSError
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.TypeNotConvertible.rawValue, "The error should be due to `name` not being convertible to `number`.")
        }
    }
    
    func testJSONErrorUnexpectedType() {
        let json = JSON.createJSONFrom(data!)
        let matt = json["people"]["name"].string
        switch matt {
        case .Success:
            XCTFail("The `name` key should not be availabe as a subscript for the `Array` `people`.")
        case .Failure(let errorType):
            let error = errorType as! NSError
            XCTAssertEqual(error.code, JSON.BNRSwiftJSONErrorCode.UnexpectedType.rawValue, "The `people` `Array` is not subscriptable with `String`s.")
        }
    }
}
