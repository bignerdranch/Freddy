// Copyright (C) 2016 Big Nerd Ranch, Inc. Licensed under the MIT license WITHOUT ANY WARRANTY.

import XCTest
import Freddy

class JSONSerializingTests: XCTestCase {
    let json = JSONFromFixture("sample.JSON")
    let noWhiteSpaceData = dataFromFixture("sampleNoWhiteSpace.JSON")

    func testThatJSONCanBeSerializedToNSData() {
        let data = try! json.serialize()
        XCTAssertGreaterThan(data.length, 0, "There should be data.")
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

    func testThatJSONDataSerializationHandlesBoolsCorrectly() {
        let json = JSON.Dictionary([
            "foo": .Bool(true),
            "bar": .Bool(false),
            "baz": .Int(123),
        ])
        let data = try! json.serialize()
        let deserializedResult = try! JSON(data: data).dictionary()
        let deserialized = JSON.Dictionary(deserializedResult)
        XCTAssertEqual(json, deserialized, "Serialize/Deserialize succeed with Bools")
    }
    
    func testThatJSONStringSerializationHandlesBoolsCorrectly() {
        let json = JSON.Dictionary([
            "foo": .Bool(true),
            "bar": .Bool(false),
            "baz": .Int(123),
        ])
        let string = try! json.serializeString()
        let deserializedResult = try! JSON(jsonString: string).dictionary()
        let deserialized = JSON.Dictionary(deserializedResult)
        XCTAssertEqual(json, deserialized, "Serialize/Deserialize succeed with Bools")
    }
}


func dataFromFixture(filename: String) -> NSData {
    let testBundle = NSBundle(forClass: JSONSerializingTests.self)
    guard let URL = testBundle.URLForResource(filename, withExtension: nil) else {
        preconditionFailure("failed to find file \"\(filename)\" in bundle \(testBundle)")
    }

    guard let data = NSData(contentsOfURL: URL) else {
        preconditionFailure("NSData failed to read file \(URL.path)")
    }
    return data
}


func JSONFromFixture(filename: String) -> JSON {
    let data = dataFromFixture(filename)
    do {
        let json = try JSON(data: data)
        return json
    } catch {
        preconditionFailure("failed deserializing JSON fixture in \(filename): \(error)")
    }
}
