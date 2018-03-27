//
//  JSONTests.swift
//  Freddy
//
//  Created by David House on 1/14/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Foundation
@testable import Freddy

class JSONTests: XCTestCase {
    
    static var allTests : [(String, (JSONTests) -> () throws -> Void)] {
        return [
//            ("testInitializingFromData", testInitializingFromData),
//            ("DoNotRuntestInitializingFromEmptyData", DoNotRuntestInitializingFromEmptyData), // TODO: Do not run
            ("testInitializingFromString", testInitializingFromString),
//            ("DoNotRuntestInitializingFromEmptyString", DoNotRuntestInitializingFromEmptyString), // TODO: Do not run
        ]
    }

    var sampleData: Data!
    
    override func setUp() {
        super.setUp()
        
        #if !os(Linux) // Bundle(for:) is NSNotImplemented
        let testBundle = Bundle(for: JSONTests.self)
        do {
            guard let data = try testBundle.url(forResource: "sample", withExtension: "JSON").flatMap({ try Data(contentsOf: $0)} ) else {
                XCTFail("Could not read sample data from test bundle")
                return
            }
            
            sampleData = data
            
        } catch {
            XCTFail("Could not read sample data from test bundle: \(error)")
            return
        }
        #endif
        
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
