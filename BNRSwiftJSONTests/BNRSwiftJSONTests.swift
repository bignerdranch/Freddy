//
//  BNRSwiftJSONTests.swift
//  BNRSwiftJSONTests
//
//  Created by Matthew D. Mathias on 3/25/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
import BNRSwiftJSON

class BNRSwiftJSONTests: XCTestCase {

    private var json: JSON!
    private var noWhiteSpaceData: NSData!

    func parser() -> JSONParserType.Type {
        return JSONParser.self
    }

    override func setUp() {
        super.setUp()

        let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
        guard let data = testBundle.URLForResource("sample", withExtension: "JSON").flatMap(NSData.init) else {
            XCTFail("Could not read sample data from test bundle")
            return
        }

        do {
            self.json = try JSON(data: data, usingParser: parser())
        } catch {
            XCTFail("Could not parse sample JSON: \(error)")
            return
        }

        guard let noWhiteSpaceData = testBundle.URLForResource("sampleNoWhiteSpace", withExtension: "JSON").flatMap(NSData.init) else {
            XCTFail("Could not read sample data (no whitespace) from test bundle")
            return
        }

        self.noWhiteSpaceData = noWhiteSpaceData
    }

    func testThatJSONCanBeSerialized() {
        let data = try! json.serialize()
        XCTAssertGreaterThan(data.length, 0, "There should be data.")
    }

    func testThatJSONDataIsEqual() {
        let serializedJSONData = try! json.serialize()
        let noWhiteSpaceJSON = try! JSON(data: noWhiteSpaceData, usingParser: parser())
        let noWhiteSpaceSerializedJSONData = try! noWhiteSpaceJSON.serialize()
        XCTAssertEqual(serializedJSONData, noWhiteSpaceSerializedJSONData, "Serialized data should be equal.")
    }

    func testThatJSONSerializationMakesEqualJSON() {
        let serializedJSONData = try! json.serialize()
        let serialJSON = try! JSON(data: serializedJSONData, usingParser: parser())
        XCTAssert(json == serialJSON, "The JSON values should be equal.")
    }

    func testThatJSONSerializationHandlesBoolsCorrectly() {
        let json = JSON.Dictionary([
            "foo": .Bool(true),
            "bar": .Bool(false),
            "baz": .Int(123),
        ])
        let data = try! json.serialize()
        let deserializedResult = try! JSON(data: data, usingParser: parser()).dictionary()
        let deserialized = JSON.Dictionary(deserializedResult)
        XCTAssertEqual(json, deserialized, "Serialize/Deserialize succeed with Bools")
    }
    
    func testThatJSONCanCreatePeople() {
        let peopleJSON = try! json.array("people")
        for personJSON in peopleJSON {
            let person = try? Person(json: personJSON)
            XCTAssertEqual(person?.name.isEmpty, false, "People should have names.")
        }
    }
    
    func testThatArrayAtPathExtractsValue() {
        let peopleJSON = try? json.array("people")
        XCTAssertEqual(peopleJSON?.isEmpty, false)
    }

    func testThatMapCanCreateArrayOfPeople() {
        let peopleJSON = try! json.array("people")
        let people = try! peopleJSON.map(Person.init)
        for person in people {
            XCTAssertNotEqual(person.name, "", "There should be a name.")
        }
    }
    
    func testThatMapAndPartitionCanGatherPeopleInSuccesses() {
        let peopleJSON = try! json.array("people")
        let (people, errors) = peopleJSON.mapAndPartition(Person.init)
        XCTAssertEqual(errors.count, 0, "There should be no errors in `failures`.")
        XCTAssertGreaterThan(people.count, 0, "There should be people in `successes`.")
    }
    
    func testThatMapAndPartitionCanGatherErrorsInFailures() {
        let jsonArray: JSON = [
            [ "name": "Matt Mathias", "age": 32, "spouse": true ],
            [ "name": "Drew Mathias", "age": 33, "spouse": true ],
            [ "name": "Sargeant Pepper" ]
        ]
        let data = try! jsonArray.serialize()
        let deserializedArray = try! JSON(data: data, usingParser: parser()).array()
        let (successes, failures) = deserializedArray.mapAndPartition(Person.init)
        XCTAssertEqual(failures.count, 1, "There should be one error in `failures`.")
        XCTAssertEqual(successes.count, 2, "There should be two people in `successes`.")
    }
    
    func testThatSubscriptingJSONWorksForTopLevelObject() {
        let success = try? json.bool("success")
        XCTAssertEqual(success, true, "There should be `success`.")
    }
    
    func testThatPathSubscriptingPerformsNesting() {
        for z in try! json.array("states", "Georgia") {
            XCTAssertNotNil(try? z.int(), "The `Int` should not be `nil`.")
        }
    }

    func testJSONSubscriptWithInt() {
        let mattmatt = try? json.string("people", 0, "name")
        XCTAssertEqual(mattmatt, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
    }

    func testJSONErrorKeyNotFound() {
        do {
            _ = try json.array("peopl")
        } catch JSON.Error.KeyNotFound(let key) {
            XCTAssert(key == "peopl", "The error should be due to the key not being found.")
        } catch {
            XCTFail("The error should be due to the key not being found, but was: \(error).")
        }
    }
    
    func testJSONErrorIndexOutOfBounds() {
        do {
            _ = try json.dictionary("people", 4)
        } catch JSON.Error.IndexOutOfBounds(let index) {
            XCTAssert(index == 4, "The error should be due to the index being out of bounds.")
        } catch {
            XCTFail("The error should be due to the index being out of bounds, but was: \(error).")
        }
    }
    
    func testJSONErrorTypeNotConvertible() {
        do {
            _ = try json.int("people", 0, "name")
        } catch JSON.Error.ValueNotConvertible(let type) {
            XCTAssert(type == Swift.IntMax, "The error should be due the value not being an `Int` case, but was \(type).")
        } catch {
            XCTFail("The error should be due to `name` not being convertible to `int`, but was: \(error).")
        }
    }
    
    func testJSONErrorUnexpectedSubscript() {
        do {
            _ = try json.string("people", "name")
        } catch JSON.Error.UnexpectedSubscript(let type) {
            XCTAssert(type == Swift.String, "The error should be due the value not being subscriptable with string `String` case, but was \(type).")
        } catch {
            XCTFail("The error should be due to the `people` `Array` not being subscriptable with `String`s, but was: \(error).")
        }
    }
}

class BNRSwiftJSONWithNSJSONTests: BNRSwiftJSONTests {

    override func parser() -> JSONParserType.Type {
        return NSJSONSerialization.self
    }

}
