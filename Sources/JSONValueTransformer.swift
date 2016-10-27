//
//  JSONValueTransformer.swift
//  Freddy
//
//  Created by John Gallagher on 8/5/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

public enum JSONValueTransformerError: ErrorType {
    case InvalidInputType
}

public protocol JSONValueTransformer {
    associatedtype Out

    func transformed(value: JSON) throws -> Out
}

public struct JSONDateTransformer {
    public enum Error: ErrorType {
        case InvalidValue(String)
    }

    public enum ISO8601: String {
        case WithoutTimeZone                  = "yyyy-MM-dd'T'HH:mm:ss"
        case WithTimeZone                     = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        case WithTimeZoneAndFractionalSeconds = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    }

    private let formatter: NSDateFormatter

    public init(iso8601: ISO8601) {
        self.init(dateFormat: iso8601.rawValue)
    }

    public init(dateFormat: String) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.calendar = NSCalendar(identifier: NSCalendarIdentifierISO8601)
        self.init(formatter: formatter)
    }

    public init(formatter: NSDateFormatter) {
        self.formatter = formatter
    }
}

extension JSONDateTransformer: JSONValueTransformer {
    public func transformed(value: JSON) throws -> NSDate {
        let s = try value.string()
        guard let date = formatter.dateFromString(s) else {
            throw Error.InvalidValue(s)
        }

        return date
    }
}
