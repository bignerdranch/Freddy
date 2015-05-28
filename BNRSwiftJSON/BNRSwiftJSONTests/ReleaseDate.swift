//
//  ReleaseDate.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

import Foundation
import Argo
import BNRSwiftJSON
import Result

enum ReleaseDate {
    case Full(NSDate)
    case Month(NSDateComponents)
    case Year(NSDateComponents)

    init?(string: String) {
        if let fullDate = ReleaseDateFullFormatter().dateFromString(string) {
            self = .Full(fullDate)
        } else if let withMonth = ReleaseDateMonthFormatter().dateFromString(string) {
            let components = ReleaseDateMonthFormatter().calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitCalendar, fromDate: withMonth)
            self = .Month(components)
        } else if let justYear = ReleaseDateYearFormatter().dateFromString(string) {
            let components = ReleaseDateYearFormatter().calendar.components(.CalendarUnitYear | .CalendarUnitCalendar, fromDate: justYear)
            self = .Year(components)
        } else {
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .Full(let date):
            return ReleaseDateFullFormatter().stringFromDate(date)
        case .Month(let components):
            let formatter = ReleaseDateMonthFormatter()
            let date = formatter.calendar.dateFromComponents(components)!
            return formatter.stringFromDate(date)
        case .Year(let components):
            let formatter = ReleaseDateYearFormatter()
            let date = formatter.calendar.dateFromComponents(components)!
            return formatter.stringFromDate(date)
        }
    }
}

// MARK: Argo-style

extension ReleaseDate: Decodable {
    static func decode(j: Argo.JSON) -> Decoded<ReleaseDate> {
        switch j {
        case .String(let s):
            return .fromOptional(ReleaseDate(string: s))
        default:
            return .TypeMismatch("\(j) is not a String")
        }
    }
}

// MARK: BNRSwiftJSON-style

extension ReleaseDate: JSONDecodable {

    static func createWithJSON(value: BNRSwiftJSON.JSON) -> Result<ReleaseDate> {
        if let string = value.string {
            if let ret = ReleaseDate(string: string) {
                return Result(success: ret)
            } else {
                return Result(failure: NSError())
            }
        } else {
            return Result(failure: NSError())
        }
    }

}
