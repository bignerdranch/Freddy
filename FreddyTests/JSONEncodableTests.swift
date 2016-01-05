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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testThatJSONEncodableEncodesString() {
        let matt = "Matt"
        let comparisonMatt = JSON.String(matt)
        let testMatt = matt.encodeToJSON()
        XCTAssertTrue(comparisonMatt == testMatt, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesBool() {
        let leFalse = false
        let comparisonFalse: JSON = false
        let testFalse = leFalse.encodeToJSON()
        XCTAssertTrue(comparisonFalse == testFalse, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesInt() {
        let thirtyTwo = 32
        let comparisonThirtyTwo = JSON.Int(thirtyTwo)
        let testThirtyTwo = thirtyTwo.encodeToJSON()
        XCTAssertTrue(comparisonThirtyTwo == testThirtyTwo, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesDouble() {
        let threePointOneFour = 3.14
        let comparisonThreePointOneFour = JSON.Double(threePointOneFour)
        let testThreePointOneFour = threePointOneFour.encodeToJSON()
        XCTAssertTrue(comparisonThreePointOneFour == testThreePointOneFour, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesModelType() {
        let matt = Person(name: "Matt", age: 32, spouse: true)
        let comparisonMatt: JSON = ["name": "Matt", "age": 32, "spouse": true]
        let testMatt = matt.encodeToJSON()
        XCTAssertTrue(comparisonMatt == testMatt, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesArray() {
        let veggies = ["lettuce", "onion"]
        let comparisonVeggies = JSON.Array(["lettuce", "onion"])
        let testVeggies = veggies.encodeToJSON()
        XCTAssertTrue(comparisonVeggies == testVeggies, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesDictionary() {
        let people = ["matt": 32, "drew": 33]
        let comparisonPeople: JSON = ["matt": 32, "drew": 33]
        let testPeople = people.encodeToJSON()
        XCTAssertTrue(comparisonPeople == testPeople, "These should be the same!")
    }
    
    func testThatJSONEncodableEncodesArrayOfModels() {
        let people = [ Person(name: "Matt", age: 32, spouse: true), Person(name: "Drew", age: 33, spouse: true) ]
        let comparisonPeople: JSON = [ ["name": "Matt", "age": 32, "spouse": true],
                                       ["name": "Drew", "age": 33, "spouse": true] ]
        let testPeople = people.encodeToJSON()
        XCTAssertTrue(comparisonPeople == testPeople, "These should be the same!")
    }
}
