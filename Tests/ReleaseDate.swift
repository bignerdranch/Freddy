//
//  ReleaseDate.swift
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

import Foundation
import Freddy

enum ReleaseDate {
    case Unknown
    case Full(NSDate)
    case Month(NSDateComponents)
    case Year(NSDateComponents)

    enum Error: ErrorType {
        case InvalidDateFormat
    }

    init(string: String) throws {
        if let fullDate = ReleaseDateFullFormatter().dateFromString(string) {
            self = .Full(fullDate)
        } else if let withMonth = ReleaseDateMonthFormatter().dateFromString(string) {
            let components = ReleaseDateMonthFormatter().calendar.components([.Year, .Month, .Calendar], fromDate: withMonth)
            self = .Month(components)
        } else if let justYear = ReleaseDateYearFormatter().dateFromString(string) {
            let components = ReleaseDateYearFormatter().calendar.components([.Year, .Calendar], fromDate: justYear)
            self = .Year(components)
        } else {
            throw Error.InvalidDateFormat
        }
    }

    var stringValue: String? {
        switch self {
        case .Unknown:
            return nil
        case .Full(let date):
            return ReleaseDateFullFormatter().stringFromDate(date)
        case .Month(let components):
            let formatter = ReleaseDateMonthFormatter()
            return formatter.calendar.dateFromComponents(components).map(formatter.stringFromDate)
        case .Year(let components):
            let formatter = ReleaseDateYearFormatter()
            return formatter.calendar.dateFromComponents(components).map(formatter.stringFromDate)
        }
    }
}

// MARK: Freddy-style

extension ReleaseDate: JSONDecodable {

    init(json: Freddy.JSON) throws {
        try self.init(string: try json.string())
    }

}
