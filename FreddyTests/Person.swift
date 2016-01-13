//
//  Person.swift
//  FreddyTests
//
//  Created by Matthew D. Mathias on 3/21/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Freddy

public struct Person: CustomStringConvertible {
    public let name: String
    public var age: Int
    public let spouse: Bool
    
    public var description: String {
        return "Name: \(name), age: \(age), married: \(spouse)"
    }
}

extension Person: JSONDecodable {
    public init(json value: JSON) throws {
        name = try value.string("name")
        age = try value.int("age")
        spouse = try value.bool("spouse")
    }
}

extension Person: JSONEncodable {
    public func toJSON() -> JSON {
        return .Dictionary(["name": .String(name), "age": .Int(age), "spouse": .Bool(spouse)])
    }
}