//
//  BNRSwiftJSONTests.swift
//  BNRSwiftJSONTests
//
//  Created by Matthew D. Mathias on 3/25/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import XCTest
import BNRSwiftJSON
import Result

class BNRSwiftJSONTests: XCTestCase {
    
    lazy var data: NSData? = {
        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        return testBundle.URLForResource("sample", withExtension: "JSON").flatMap(NSData.init)
    }()
    
    lazy var noWhiteSpaceData: NSData? = {
        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        return testBundle.URLForResource("sampleNoWhiteSpace", withExtension: "JSON").flatMap(NSData.init)
    }()
    
    lazy var json: JSONResult = {
        return JSON.createJSONFrom(self.data!)
    }()
    
    func testThatJSONCanCreateInstanceWithData() {
        XCTAssertTrue(json.isSuccess, "The sample JSON data should be parsed successfully.")
    }
    
    func testThatJSONCanBeSerialized() {
        let serializedJSONData = json.serialize()
        switch serializedJSONData {
        case .Success(let data):
            XCTAssertGreaterThan(data.length, 0, "There should be data.")
        case .Failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testThatJSONDataIsEqual() {
        let serializedJSONData = json.serialize()
        let noWhiteSpaceJSON = JSON.createJSONFrom(noWhiteSpaceData!)
        let noWhiteSpaceSerializedJSONData = noWhiteSpaceJSON.serialize()
        switch (serializedJSONData, noWhiteSpaceSerializedJSONData) {
        case (.Success(let sjd), .Success(let nwssjd)):
            XCTAssertEqual(sjd, nwssjd, "Serialized data should be equal.")
        default:
            XCTFail("Serialized data should be equal.")
        }
    }
    
    func testThatJSONSerializationMakesEqualJSON() {
        let serializedJSONData = json.serialize()
        switch serializedJSONData {
        case .Success(let data):
            let serialJSON = JSON.createJSONFrom(data)
            XCTAssertEqual(json, serialJSON, "The JSON values should be equal.")
        case .Failure(let error):
            XCTFail("Failed with error: \(error)")
        }
    }

    func testThatJSONSerializationHandlesBoolsCorrectly() {
        let json = JSON.Dictionary([
            "foo": .Bool(true),
            "bar": .Bool(false),
            "baz": .Int(123),
        ])
        let data = json.serialize().value!
        let deserializedResult = JSON.createJSONFrom(data).dictionary
        let deserialized = JSON.Dictionary(deserializedResult.value!)
        XCTAssertEqual(json, deserialized, "Serialize/Deserialize succeed with Bools")
    }
    
    func testThatJSONCanCreatePeople() {
        let peopleArray = json["people"].array
        switch peopleArray {
        case .Success(let people):
            for person in people {
                let per = Person.createWithJSON(person)
                switch per {
                case .Success(let p):
                    XCTAssertNotEqual(p.name, "", "People should have names.")
                case .Failure:
                    XCTFail("There should be no `error`.")
                }
            }
        case .Failure:
            XCTFail("There should be no error.")
        }
    }
    
    func testThatCollectAllSuccessesCanCreateArrayOfPeople() {
        let peopleArray = json["people"].array.flatMap { collectAllSuccesses($0.map(Person.createWithJSON)) }
        switch peopleArray {
        case .Success(let value):
            for person in value {
                XCTAssertNotEqual(person.name, "", "There should be a name.")
            }
        case .Failure:
            XCTFail("There should be no failure.")
        }
    }

    func testThatSplitResultsCanCreateArrayOfPeople() {
        let peopleArray = json["people"].array
        switch peopleArray {
        case .Success(let people):
            let (successes, failures) = partitionResults(people.map { Person.createWithJSON($0) })
            XCTAssertNotEqual(successes.count, 0, "There should be successes.")
            XCTAssertEqual(failures.count, 0, "There should be no failures.")
        case .Failure:
            XCTFail("There should be no error.")
        }
    }
    
    func testSplitResultCanGatherPeopleInSuccesses() {
        let people = splitResult(json["people"].array, Person.createWithJSON)
        switch people {
        case .Success(let result):
            XCTAssertGreaterThan(result.successes.count, 0, "There should be people in `successes`.")
            XCTAssertEqual(result.failures.count, 0, "There should be no errors in `failures`.")
        case .Failure:
            XCTFail("There should be no error.")
        }
    }
    
    func testSplitResultCanGatherErrorsInFailures() {
        let json = JSON.Array([
                JSON.Dictionary(["name": JSON.String("Matt Mathias"), "age": JSON.Int(32), "spouse": JSON.Bool(true)]),
                JSON.Dictionary(["name": JSON.String("Drew Mathias"), "age": JSON.Int(33), "spouse": JSON.Bool(true)]),
                JSON.Dictionary(["name": JSON.String("Sargeant Pepper"), "age": JSON.Int(25)])
            ])
        let data = json.serialize().value!
        let deserializedResult = JSON.createJSONFrom(data).array
        let people = splitResult(deserializedResult, Person.createWithJSON)
        switch people {
        case .Success(let result):
            XCTAssertEqual(result.successes.count, 2, "There should be two people in `successes`.")
            XCTAssertEqual(result.failures.count, 1, "There should be one error in `failures`.")
        case .Failure:
            XCTFail("The result should `succeed` with errors in tuple, and not fail with an `NSError` in `.Failure`.")
        }
    }
    
    func testThatSubscriptingJSONWorksForTopLevelObject() {
        let success = json["success"].bool
        switch success {
        case .Success(let s):
            XCTAssertTrue(s, "There should be `success`.")
        case .Failure(let error):
            XCTFail("There should be no error: \(error)")
        }
    }
    
    func testThatJSONNullMatchesNullValue() {
        let key = json["key"].null
        switch key {
        case .Success:
            break
        case .Failure(let error):
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testThatYouCanAccessNestedKeys() {
        let zips = json["states"]["Georgia"].array
        switch zips {
        case .Success(let zps):
            for z in zps {
                XCTAssertNotNil(z.int, "The `Int` should not be `nil`.")
            }
        case .Failure:
            XCTFail("There should be no `error`.")
        }
    }

    func testJSONSubscriptWithInt() {
        let matt = json["people"][0]["name"].string
        switch matt {
        case .Success(let n):
            XCTAssertEqual(n, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
        case .Failure(let error):
            XCTFail("There should be no error: \(error)")
        }
    }

    func testJSONErrorKeyNotFound() {
        let peopl = json["peopl"].array
        switch peopl {
        case .Success:
            XCTFail("There should be no people.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.ErrorCode.KeyNotFound.rawValue, "The error should be due to the key not being found.")
        }
    }
    
    func testJSONErrorIndexOutOfBounds() {
        let person = json["people"][4].dictionary
        switch person {
        case .Success:
            XCTFail("There should be no person at index 4.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.ErrorCode.IndexOutOfBounds.rawValue, "The error should be due to the index being out of bounds.")
        }
    }
    
    func testJSONErrorTypeNotConvertible() {
        let matt = json["people"][0]["name"].int
        switch matt {
        case .Success:
            XCTFail("The `name` should not be convertible to `int`.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.ErrorCode.TypeNotConvertible.rawValue, "The error should be due to `name` not being convertible to `int`.")
        }
    }
    
    func testJSONErrorUnexpectedType() {
        let matt = json["people"]["name"].string
        switch matt {
        case .Success:
            XCTFail("The `name` key should not be availabe as a subscript for the `Array` `people`.")
        case .Failure(let error):
            XCTAssertEqual(error.code, JSON.ErrorCode.UnexpectedType.rawValue, "The `people` `Array` is not subscriptable with `String`s.")
        }
    }
}
