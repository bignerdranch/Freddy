//
//  JSONTransformerTests.swift
//  Freddy
//
//  Created by John Gallagher on 8/5/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Freddy

class JSONTransformerTests: XCTestCase {

    let dateTestData = [
        ("1970-01-01T00:01:01", NSDate(timeIntervalSince1970: 61), JSONDateTransformer.ISO8601.WithoutTimeZone),
        ("1970-01-01T00:01:02-04:00", NSDate(timeIntervalSince1970: 62 + 3600*4), JSONDateTransformer.ISO8601.WithTimeZone),
        ("1970-01-01T00:01:01.125-04:00", NSDate(timeIntervalSince1970: 61.125 + 3600*4), JSONDateTransformer.ISO8601.WithTimeZoneAndFractionalSeconds),
    ]

    func testISO8601DateTransformer() {
        for (s, expectedDate, format) in dateTestData {
            let json = JSON.String(s)
            do {
                let date = try json.transformed(transformer: JSONDateTransformer(iso8601: format))
                let diff = date.timeIntervalSinceDate(expectedDate)
                XCTAssertEqualWithAccuracy(diff, 0, accuracy: 0.01)
            } catch {
                XCTFail("Unexpected error \(error)")
            }
        }
    }

}
