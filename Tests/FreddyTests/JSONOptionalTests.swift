//
//  JSONOptionalTests.swift
//  Freddy
//
//  Created by David House on 2/2/17.
//  Copyright © 2017 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Freddy

class JSONOptionalTests: XCTestCase {
    
    func testThatJSONCanBeCreatedFromDoubleOptionals() {
        
        let doubleWithValue: Double? = 123.45
        let doubleWithoutValue: Double? = nil
        
        XCTAssertEqual(JSON(doubleWithValue), .double(123.45))
        XCTAssertEqual(JSON(doubleWithoutValue), .null)
    }
    
    func testThatJSONCanBeCreatedFromIntOptionals() {
        
        let intWithValue: Int? = 123
        let intWithoutValue: Int? = nil
        
        XCTAssertEqual(JSON(intWithValue), .int(123))
        XCTAssertEqual(JSON(intWithoutValue), .null)
    }

    func testThatJSONCanBeCreatedFromBoolOptionals() {
        
        let boolWithValue: Bool? = true
        let boolWithoutValue: Bool? = nil
        
        XCTAssertEqual(JSON(boolWithValue), .bool(true))
        XCTAssertEqual(JSON(boolWithoutValue), .null)
    }
    
    func testThatJSONCanBeCreatedFromStringOptionals() {
        
        let stringWithValue: String? = "fred"
        let stringWithoutValue: String? = nil
        
        XCTAssertEqual(JSON(stringWithValue), .string("fred"))
        XCTAssertEqual(JSON(stringWithoutValue), .null)
    }
}
