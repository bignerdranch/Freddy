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

    var sampleData:NSData!
    
    override func setUp() {
        super.setUp()
        
        let testBundle = NSBundle(forClass: JSONSubscriptingTests.self)
        guard let data = testBundle.URLForResource("sample", withExtension: "JSON").flatMap(NSData.init) else {
            XCTFail("Could not read sample data from test bundle")
            return
        }
        sampleData = data
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
            _ = try JSON(data: NSData())
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