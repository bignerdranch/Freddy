//
//  Person.swift
//  FreddyTests
//
//  Created by Matthew D. Mathias on 3/21/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Freddy

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
    public init(json value: JSON) throws {
        name = try value.getString(at: "name")
        age = try value.getInt(at: "age")
        eyeColor = try value.decode(at: "eyeColor")
        spouse = try value.getBool(at: "spouse")
    }
}

extension Person: JSONEncodable {
    public func toJSON() -> JSON {
        return .dictionary(["name": .string(name), "age": .int(age), "eyeColor": eyeColor.toJSON(), "spouse": .bool(spouse)])
    }
}

public final class PersonClass: CustomStringConvertible {
    public enum EyeColor: String {
        case Brown = "brown"
        case Blue = "blue"
        case Green = "green"
    }
    
    public let name: String
    public var age: Int
    public let eyeColor: EyeColor
    public let spouse: Bool
    
    init(name: String, age: Int, eyeColor: EyeColor, spouse: Bool) {
        self.name = name
        self.age = age
        self.eyeColor = eyeColor
        self.spouse = spouse
    }
    
    public var description: String {
        return "Name: \(name), age: \(age), married: \(spouse)"
    }
}

extension PersonClass.EyeColor: JSONDecodable {}
extension PersonClass.EyeColor: JSONEncodable {}

extension PersonClass: JSONStaticDecodable {
    
    public static func fromJSON(json value: JSON) throws -> PersonClass {
        let name = try value.getString(at: "name")
        let age = try value.getInt(at: "age")
        let eyeColor: EyeColor = try value.decode(at: "eyeColor")
        let spouse = try value.getBool(at: "spouse")
        return PersonClass(name: name, age: age, eyeColor: eyeColor, spouse: spouse)
    }
}
