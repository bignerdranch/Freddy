//
//  ResultTests.swift
//  ResultTests
//
//  Created by John Gallagher on 4/8/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Result

extension Bool: ErrorType {}

class ResultTests: XCTestCase {

    func testThatNSErrorIsAValidErrorType() {
        let error = NSError(domain: "com.bignerdranch", code: 0, userInfo: nil)
        let result: Result<Int> = Result(failure: error)
        XCTAssertEqual(result.failureValue as! NSError, error)
    }

    func testPartitionResults() {
        let results: [Result<Int>] = [
            Result(success: 1),
            Result(success: 2),
            Result(failure: true as ErrorType),
            Result(success: 3),
            Result(failure: false as ErrorType),
        ]

        let (successes, failures) = partitionResults(results)
        XCTAssertEqual(successes, [1,2,3])
        XCTAssertEqual(failures.count, 2)
        XCTAssertEqual(failures[0] as! Bool, true)
        XCTAssertEqual(failures[1] as! Bool, false)
    }
    
}
