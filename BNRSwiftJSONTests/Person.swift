//
//  Person.swift
//  BNRSwiftJSONTests
//
//  Created by Matthew D. Mathias on 3/21/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import BNRSwiftJSON

public struct Person: CustomStringConvertible {
    public let name: String
    public var age: IntMax
    public let spouse: Bool
    
    public init(name: String, age: IntMax, spouse: Bool) {
        self.name = name
        self.age = age
        self.spouse = spouse
    }
    
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
