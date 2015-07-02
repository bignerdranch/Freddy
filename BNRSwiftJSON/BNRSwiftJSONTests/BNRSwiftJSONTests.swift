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
        let path = testBundle.pathForResource("sample", ofType: "JSON")
        
        if let p = path, u = NSURL(fileURLWithPath: p) {
            return NSData(contentsOfURL: u)
        }
        
        return nil
    }()
    
    lazy var noWhiteSpaceData: NSData? = {
        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        let path = testBundle.pathForResource("sampleNoWhiteSpace", ofType: "JSON")
        
        if let p = path, u = NSURL(fileURLWithPath: p) {
            return NSData(contentsOfURL: u)
        }
        
        return nil
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
            XCTAssertGreaterThan(data.value.length, 0, "There should be data.")
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
            XCTAssertEqual(sjd.value, nwssjd.value, "Serialized data should be equal.")
        default:
            XCTFail("Serialized data should be equal.")
        }
    }
    
    func testThatJSONSerializationMakesEqualJSON() {
        let serializedJSONData = json.serialize()
        switch serializedJSONData {
        case .Success(let data):
            let serialJSON = JSON.createJSONFrom(data.value)
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
    
    func testThatCollectAllSuccessesCanCreateArrayOfPeople() {
        let peopleArray = json["people"].array.flatMap { collectAllSuccesses(map($0, Person.createWithJSON)) }
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
        let people = splitResult(json["people"].array, Person.createWithJSON)
        switch people {
        case .Success(let result):
            XCTAssertGreaterThan(result.value.successes.count, 0, "There should be people in `successes`.")
            XCTAssertEqual(result.value.failures.count, 0, "There should be no errors in `failures`.")
        case .Failure(let error):
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
            XCTAssertEqual(result.value.successes.count, 2, "There should be two people in `successes`.")
            XCTAssertEqual(result.value.failures.count, 1, "There should be one error in `failures`.")
        case .Failure(let error):
            XCTFail("The result should `succeed` with errors in tuple, and not fail with an `NSError` in `.Failure`.")
        }
    }
    
    func testThatSubscriptingJSONWorksForTopLevelObject() {
        let success = json["success"].bool
        switch success {
        case .Success(let s):
            XCTAssertTrue(s.value, "There should be `success`.")
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
            for z in zps.value {
                XCTAssertNotNil(z.int, "The `Int` should not be `nil`.")
            }
        case .Failure(let error):
            XCTFail("There should be no `error`.")
        }
    }

    func testJSONSubscriptWithInt() {
        let matt = json["people"][0]["name"].string
        switch matt {
        case .Success(let n):
            XCTAssertEqual(n.value, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
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
            XCTAssertEqual(error.value.code, JSON.ErrorCode.KeyNotFound.rawValue, "The error should be due to the key not being found.")
        }
    }
    
    func testJSONErrorIndexOutOfBounds() {
        let person = json["people"][4].dictionary
        switch person {
        case .Success:
            XCTFail("There should be no person at index 4.")
        case .Failure(let error):
            XCTAssertEqual(error.value.code, JSON.ErrorCode.IndexOutOfBounds.rawValue, "The error should be due to the index being out of bounds.")
        }
    }
    
    func testJSONErrorTypeMismatch() {
        let matt = json["people"][0]["name"].int
        switch matt {
        case .Success(let name):
            XCTFail("The `name` should not be convertible to `int`.")
        case .Failure(let error):
            XCTAssertEqual(error.value.code, JSON.ErrorCode.TypeMismatch.rawValue, "The error should be due to `name` not being convertible to `int`.")
        }
    }
    
    func testJSONErrorSubscriptTypeMismatch() {
        let matt = json["people"]["name"].string
        switch matt {
        case .Success:
            XCTFail("The `name` key should not be availabe as a subscript for the `Array` `people`.")
        case .Failure(let error):
            XCTAssertEqual(error.value.code, JSON.ErrorCode.SubscriptTypeMismatch.rawValue, "The `people` `Array` is not subscriptable with `String`s.")
        }
    }

    func testThatOrFallsBackOnMissingKeys() {
        let height = json["people"][0]["height"].or(6.1).double
        BNRAssertEqualWithAccuracy(height.value, 6.1, DBL_EPSILON)
    }

    func testThatOrDoesNotFallBackOnMissingKeysEarlierInAChain() {
        let height = json["peopl"][0]["height"].or(6.1).double
        BNRAssertEqual(height.error?.code, JSON.ErrorCode.KeyNotFound.rawValue)
    }

    func testThatOrFallsBackOnMissingIndices() {
        let dev = json["jobs"][10].or("developer").string
        BNRAssertEqual(dev.value, "developer")
    }

    func testThatOrDoesNotFallBackOnTypeMismatches() {
        for r in [
            json["people"]["name"].or("test").string,
            json["people"][0][1].or("test").string,
            json["people"][0]["age"].or("test").string,
        ] {
            XCTAssert(r.error != nil, "Unexpected successful parse: \(r)")
        }
    }
}
