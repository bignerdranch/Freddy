//
//  Person.swift
//  BNRSwiftJSONTests
//
//  Created by Matthew D. Mathias on 3/21/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import BNRSwiftJSON
import Result

public struct Person: CustomStringConvertible {
    public let name: String
    public var age: Int
    public let spouse: Bool
    
    public init(name: String, age: Int, spouse: Bool) {
        self.name = name
        self.age = age
        self.spouse = spouse
    }
    
    public var description: String {
        return "Name: \(name), age: \(age), married: \(spouse)"
    }
}

extension Person: JSONDecodable {
    public static func createWithJSON(value: JSON) -> Result<Person, NSError> {
        let name = value["name"].string
        let age = value["age"].int
        let isMarried = value["spouse"].bool
        
        return mapAll(name, age, isMarried, Person.init)
    }
}
