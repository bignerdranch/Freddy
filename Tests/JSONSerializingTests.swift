// Copyright (C) 2016 Big Nerd Ranch, Inc. Licensed under the MIT license WITHOUT ANY WARRANTY.

import XCTest
import Freddy

class JSONSerializingTests: XCTestCase {
    let json = JSONFromFixture("sample.JSON")
    let noWhiteSpaceData = dataFromFixture("sampleNoWhiteSpace.JSON")

    func testThatJSONCanBeSerializedToNSData() {
        let data = try! json.serialize()
        XCTAssertGreaterThan(data.count, 0, "There should be data.")
    }
    
    func testThatJSONCanBeSerializedToString() {
        let string = try! json.serializeString()
        XCTAssertGreaterThan(string.characters.count, 0, "There should be characters.")
    }

    func testThatJSONDataIsEqual() {
        let serializedJSONData = try! json.serialize()
        let noWhiteSpaceJSON = try! JSON(data: noWhiteSpaceData)
        let noWhiteSpaceSerializedJSONData = try! noWhiteSpaceJSON.serialize()
        XCTAssertEqual(serializedJSONData, noWhiteSpaceSerializedJSONData, "Serialized data should be equal.")
    }
    
    func testThatJSONStringIsEqual() {
        let serializedJSONString = try! json.serializeString()
        let noWhiteSpaceJSON = try! JSON(data: noWhiteSpaceData)
        let noWhiteSpaceSerializedJSONString = try! noWhiteSpaceJSON.serializeString()
        XCTAssertEqual(serializedJSONString, noWhiteSpaceSerializedJSONString, "Serialized string should be equal.")
    }

    func testThatJSONDataSerializationMakesEqualJSON() {
        let serializedJSONData = try! json.serialize()
        let serialJSON = try! JSON(data: serializedJSONData)
        XCTAssert(json == serialJSON, "The JSON values should be equal.")
    }
    
    func testThatJSONStringSerializationMakesEqualJSON() {
        let serializedJSONString = try! json.serializeString()
        let serialJSON = try! JSON(jsonString: serializedJSONString)
        XCTAssert(json == serialJSON, "The JSON values should be equal.")
    }

    func testThatJSONSerializationHandlesBoolsCorrectly() {
        let json = JSON.dictionary([
            "foo": .bool(true),
            "bar": .bool(false),
            "baz": .int(123),
        ])
        let data = try! json.serialize()
        let deserializedResult = try! JSON(data: data).getDictionary()
        let deserialized = JSON.dictionary(deserializedResult)
        XCTAssertEqual(json, deserialized, "Serialize/Deserialize succeed with Bools")
    }
    
    func testThatJSONStringSerializationHandlesBoolsCorrectly() {
        let json = JSON.dictionary([
            "foo": .bool(true),
            "bar": .bool(false),
            "baz": .int(123),
        ])
        let string = try! json.serializeString()
        let deserializedResult = try! JSON(jsonString: string).getDictionary()
        let deserialized = JSON.dictionary(deserializedResult)
        XCTAssertEqual(json, deserialized, "Serialize/Deserialize succeed with Bools")
    }
}


func dataFromFixture(_ filename: String) -> Data {
    let testBundle = Bundle(for: JSONSerializingTests.self)
    guard let URL = testBundle.url(forResource: filename, withExtension: nil) else {
        preconditionFailure("failed to find file \"\(filename)\" in bundle \(testBundle)")
    }

    guard let data = try? Data(contentsOf: URL) else {
        preconditionFailure("Data failed to read file \(URL.path)")
    }
    return data
}


func JSONFromFixture(_ filename: String) -> JSON {
    let data = dataFromFixture(filename)
    do {
        let json = try JSON(data: data)
        return json
    } catch {
        preconditionFailure("failed deserializing JSON fixture in \(filename): \(error)")
    }
}
