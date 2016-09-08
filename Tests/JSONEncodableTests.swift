//
//  JSONEncodableTests.swift
//  Freddy
//
//  Created by Matthew Mathias on 1/4/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
@testable import Freddy

class JSONEncodableTests: XCTestCase {

    func testThatJSONEncodableEncodesString() {
        let matt = "Matt"
        let comparisonMatt = JSON.string(matt)
        let testMatt = matt.toJSON()
        XCTAssertTrue(comparisonMatt == testMatt, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesBool() {
        let leFalse = false
        let comparisonFalse: JSON = false
        let testFalse = leFalse.toJSON()
        XCTAssertTrue(comparisonFalse == testFalse, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesInt() {
        let thirtyTwo = 32
        let comparisonThirtyTwo = JSON.int(thirtyTwo)
        let testThirtyTwo = thirtyTwo.toJSON()
        XCTAssertTrue(comparisonThirtyTwo == testThirtyTwo, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesDouble() {
        let threePointOneFour = 3.14
        let comparisonThreePointOneFour = JSON.double(threePointOneFour)
        let testThreePointOneFour = threePointOneFour.toJSON()
        XCTAssertTrue(comparisonThreePointOneFour == testThreePointOneFour, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesModelType() {
        let matt = Person(name: "Matt", age: 32, eyeColor: .Brown, spouse: true)
        let comparisonMatt: JSON = ["name": "Matt", "age": 32, "eyeColor": "brown", "spouse": true]
        let testMatt = matt.toJSON()
        XCTAssertTrue(comparisonMatt == testMatt, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesArray() {
        let veggies = ["lettuce", "onion"]
        let comparisonVeggies = JSON.array(["lettuce", "onion"])
        let testVeggies = veggies.toJSON()
        XCTAssertTrue(comparisonVeggies == testVeggies, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesDictionary() {
        let people = ["matt": 32, "drew": 33]
        let comparisonPeople: JSON = ["matt": 32, "drew": 33]
        let testPeople = people.toJSON()
        XCTAssertTrue(comparisonPeople == testPeople, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesArrayOfModels() {
        let people = [ Person(name: "Matt", age: 32, eyeColor: .Green, spouse: true), Person(name: "Drew", age: 33, eyeColor: .Blue, spouse: true) ]
        let comparisonPeople: JSON = [ ["name": "Matt", "age": 32, "eyeColor": "green", "spouse": true],
                                       ["name": "Drew", "age": 33, "eyeColor": "blue", "spouse": true] ]
        let testPeople = people.toJSON()
        XCTAssertTrue(comparisonPeople == testPeople, "These should be the same!")
    }
}
