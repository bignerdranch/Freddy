//
//  JSONDecodableTests.swift
//  FreddyTests
//
//  Created by Matthew Mathias on 11/6/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Freddy

class JSONDecodableTests: XCTestCase {

    private var mattJSON: JSON!
    private var matt: Person!
    
    override func setUp() {
        super.setUp()
        
        mattJSON = ["name": "Matt Mathias", "age": 32, "eyeColor": "blue", "spouse": true]
        matt = Person(name: "Matt Mathias", age: 32, eyeColor: .Blue, spouse: true)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testThatJSONDecodableConformanceProducesInstance() {
        do {
            let decodedMatt = try Person(json: mattJSON)
            XCTAssertEqual(matt, decodedMatt, "`matt` `decodedMatt` should be equal.")
        } catch {
            XCTFail("`matt` and `decodedMatt` are not equal: \(error).")
        }
    }
    
    func testJSONDecodableExtensionOnDouble() {
        let fourPointFour = 4.4
        let fourPointFourJSON: JSON = 4.4
        let fourJSON: JSON = 4
        let fourPointFourStringJSON: JSON = "4.4"

        do {
            let decodedFourPointFour = try Double(json: fourPointFourJSON)
            let decodedFour = try Double(json: fourJSON)
            XCTAssertEqual(decodedFourPointFour, fourPointFour, "`fourPointFourJSON` and `fourPointFour` should be equal.")
            XCTAssertEqual(decodedFour, 4.0, "`decodedFour` and 4.0 should be equal.")
        } catch {
            XCTFail("Should be able to instantiate a `Double` with `JSON`: \(error).")
        }

        do {
            let decodedFourPointFour = try Double(json: fourPointFourStringJSON)
            XCTAssertEqual(decodedFourPointFour, fourPointFour, "`fourPointFour` and '4.4' `String` should be equal.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }

        do {
            _ = try Double(json: "bad")
            XCTFail("Should not be able to instantiate `Double` with `String` not matching a double representation `JSON`.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should not be covertible from 'bad' `String`.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
    }
    
    func testJSONDecodableExtensionOnInt() {
        let four = 4
        let fourJSON: JSON = 4
        let fourPointZeroJSON: JSON = 4.0
        let fourStringJSON: JSON = "4"
        let fourPointZeroStringJSON: JSON = "4.0"
        let fourPointFourStringJSON: JSON = "4.4"

        do {
            let decodedFour = try Int(json: fourJSON)
            let decodedFourPointZero = try Int(json: fourPointZeroJSON)
            XCTAssertEqual(decodedFour, four, "`four` and 4 should be equal.")
            XCTAssertEqual(decodedFourPointZero, four, "`decodedFourPointZero` and `four` should be equal.")
        } catch {
            XCTFail("Should be able to instantiate an `Int` with `JSON`: \(error).")
        }

        do {
            let decodedFour = try Int(json: fourStringJSON)
            let decodedFourPointZero = try Int(json: fourPointZeroStringJSON)
            XCTAssertEqual(decodedFour, four, "`four` and '4' `String` should be equal.")
            XCTAssertEqual(decodedFourPointZero, four, "`decodedFourPointZero` and '4.0' `String` should be equal.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }

        do {
            _ = try Int(json: fourPointFourStringJSON)
            XCTFail("Should not be able to instantiate `Int` with '4.4' `String` `JSON`.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should not be covertible from '4.4' `String`.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }

        do {
            _ = try Int(json: "bad")
            XCTFail("Should not be able to instantiate `Int` with `String` not matching an integer representation `JSON`.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should not be covertible from 'bad' `String`.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
    }
    
    func testJSONDecodableExtensionOnString() {
        let matt = "matt"
        let stringJSON: JSON = "matt"
        
        do {
            let decodedString = try String(json: stringJSON)
            XCTAssertEqual(decodedString, matt, "`decodedString` and `matt` should be equal.")
        } catch {
            XCTFail("Should be able to instantiate a `String` with `JSON`: \(error).")
        }
        
        do {
            let four = try String(json: 4)
            XCTAssertEqual(four, "4", "`four` and `4` should be equal.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should be covertible from `Int.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
        
        do {
            let twoAndHalf = try String(json: 2.5)
            XCTAssertEqual(twoAndHalf, "2.5", "`twoAndHalf` and `2.5` should be equal.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should be covertible from `Double.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
        
        do {
            let positive = try String(json: true)
            XCTAssertEqual(positive, "true", "`positive` and `true` should be equal.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should be covertible from `Bool.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
    }
    
    func testJSONDecodableExtensionOnBool() {
        let tru = true
        let boolJSON: JSON = true
        
        do {
            let decodedBool = try Bool(json: boolJSON)
            XCTAssertEqual(decodedBool, tru, "`decodedBool` and `tru` should be equal.")
        } catch {
            XCTFail("Should be able to instantiate a `Bool` with `JSON`: \(error).")
        }
        
        do {
            _ = try Bool(json: "bad")
            XCTFail("Should not be able to instantiate `Bool` with `String` `JSON`.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should not be covertible from 'bad' string.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
    }
    
    func testThatJSONBoolIsDecodable() {
        let JSONTrue: JSON = true
        do {
            let decodedTrue = try JSONTrue.getBool()
            XCTAssertTrue(decodedTrue, "`JSONTrue` should decode to `true`.")
        } catch {
            XCTFail("`JSONTrue` should decode to `true`.")
        }
    }
    
    func testThatJSONArrayIsDecodable() {
        let JSONArray: JSON = [1,2,3,4]
        
        do {
            let decodedArray = try JSONArray.getArray()
            XCTAssertEqual(decodedArray, [1,2,3,4], "`decodedArray` should match.")
        } catch {
            XCTFail("`decodedArray should be [1,2,3,4]")
        }
        
        let badJSONArray: JSON = "bad"
        do {
            _ = try badJSONArray.getArray()
            XCTFail("array should not exist.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssert(true, "\(type) should not be convertible to `[JSON]`")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
    }
    
    func testThatJSONDictionaryIsDecodable() {
        let JSONDictionary: JSON = ["Matt": 32]
        
        do {
            let decodedJSONDictionary = try JSONDictionary.getDictionary()
            XCTAssertEqual(decodedJSONDictionary, ["Matt": 32], "`decodedJSONDictionary` should equal `[Matt: 32]`.")
        } catch {
            XCTFail("`decodedJSONDictionary` should equal `[Matt: 32]`.")
        }
        
        let badJSONDictionary: JSON = 4
        do {
            _ = try badJSONDictionary.getDictionary()
            XCTFail("There should be no dictionary.")
        } catch JSON.Error.valueNotConvertible(let type) {
            XCTAssertTrue(true, "\(type) shold not be convertible to `[String: JSON]`.")
        } catch {
            XCTFail("Failed for unknown reason: \(error).")
        }
    }
    
    func testThatArrayOfCanReturnArrayOfJSONDecodable() {
        let oneTwoThreeJSON: JSON = [1,2,3]
        
        do {
            let decodedOneTwoThree = try oneTwoThreeJSON.decodedArray(type: Swift.Int)
            XCTAssertEqual(decodedOneTwoThree, [1,2,3], "`decodedOneTwoThree` should be equal to `[1,2,3]`.")
        } catch {
            XCTFail("`decodedOneTwoThree` should be equal to `[1,2,3]`.")
        }
    }
    
    func testThatDictionaryOfCanReturnDictionaryOfJSONDecodable() {
        let oneTwoThreeJSON: JSON = ["one": 1, "two": 2, "three": 3]
        
        do {
            let decodedOneTwoThree = try oneTwoThreeJSON.decodedDictionary(type: Swift.Int)
            XCTAssertEqual(decodedOneTwoThree, ["one": 1, "two": 2, "three": 3], "`decodedOneTwoThree` should be equal to `[\"one\": 1, \"two\": 2, \"three\": 3]`.")
        } catch {
            XCTFail("`decodedOneTwoThree` should be equal to `[\"one\": 1, \"two\": 2, \"three\": 3]`.")
        }
    }
    
    func testThatNullIsDecodedToNilWhenRequestedAtTopLevel() {
        let JSONDictionary: JSON = ["key": .null]
        
        do {
            let value: Int? = try JSONDictionary.getInt(at: "key", alongPath: .nullBecomesNil)
            XCTAssertEqual(value, nil)
        } catch {
            XCTFail("Should have retrieved nil for key `key` in `JSONDictionary` when specifying `ifNull` to be `true`.")
        }
    }
    
    func testThatAttemptingToDecodeNullThrowsWhenRequestedAtTopLevel() {
        let JSONDictionary: JSON = ["key": .null]
        
        do {
            let _: Int? = try JSONDictionary.getInt(at: "key")
            XCTFail("Should have thrown an error when attempting to retrieve a value for key `key` in `JSONDictionary` when not specifying `ifNull` to be `true`.")
        } catch let JSON.Error.valueNotConvertible(_, to) where to == Int.self {
            return
        } catch {
            XCTFail("An unexpected exception was thrown.")
        }
        
    }

}

extension Person: Equatable {}

public func ==(lhs: Person, rhs: Person) -> Bool {
    return (lhs.name == rhs.name) &&
           (lhs.age == rhs.age) &&
           (lhs.spouse == rhs.spouse)
}
