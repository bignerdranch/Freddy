//
//  JSONTests.swift
//  Freddy
//
//  Created by David House on 1/14/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Freddy

class JSONTests: XCTestCase {

    var sampleData:Data!
    
    override func setUp() {
        super.setUp()
        
        let testBundle = Bundle(for: JSONSubscriptingTests.self)
        guard let data = testBundle.url(forResource: "sample", withExtension: "JSON").flatMap(NSData.init(contentsOf:)) else {
            XCTFail("Could not read sample data from test bundle")
            return
        }
        sampleData = data as Data
    }
    
    func testInitializingFromData() {
        
        do {
            _ = try JSON(data: sampleData)
        } catch {
            XCTFail("Could not parse sample JSON: \(error)")
            return
        }
    }
    
    // TODO: This test currently exposes an error in the Parser
    func DoNotRuntestInitializingFromEmptyData() {
        
        do {
            _ = try JSON(data: Data())
        } catch {
            XCTFail("Could not parse empty data: \(error)")
            return
        }
    }
    
    func testInitializingFromString() {
        
        let jsonString = "{ \"slashers\": [\"Jason\",\"Freddy\"] }"
        
        do {
            _ = try JSON(jsonString: jsonString)
        } catch {
            XCTFail("Could not parse JSON from string: \(error)")
            return
        }
    }
    
    // TODO: This test currently exposes an error in the Parser
    func DoNotRuntestInitializingFromEmptyString() {
        
        do {
            _ = try JSON(jsonString: "")
        } catch {
            XCTFail("Could not parse JSON from string: \(error)")
            return
        }
    }
}
