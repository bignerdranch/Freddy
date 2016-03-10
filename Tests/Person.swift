//
//  Person.swift
//  FreddyTests
//
//  Created by Matthew D. Mathias on 3/21/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

@testable import Freddy

public struct Person: CustomStringConvertible {
    public enum EyeColor: String {
        case Brown = "brown"
        case Blue = "blue"
        case Green = "green"
    }

    public let name: String
    public var age: Int
    public let eyeColor: EyeColor
    public let spouse: Bool
    
    public var description: String {
        return "Name: \(name), age: \(age), married: \(spouse)"
    }
}

extension Person.EyeColor: JSONDecodable {}
extension Person.EyeColor: JSONEncodable {}

extension Person: JSONDecodable {
    public init(source value: JSONSource) throws {
        name = try value.string("name")
        age = try value.int("age")
        eyeColor = try value.decode("eyeColor")
        spouse = try value.bool("spouse")
    }
}

extension Person: JSONEncodable {
    public func toJSON() -> JSON {
        return .Dictionary(["name": .String(name), "age": .Int(age), "eyeColor": eyeColor.toJSON(), "spouse": .Bool(spouse)])
    }
}
