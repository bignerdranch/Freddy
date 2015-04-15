//
//  Person.swift
//  Test
//
//  Created by Matthew D. Mathias on 3/21/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation
import BNRSwiftJSON
import Result

public struct Person: Printable {
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
    public static func createWithJSON(value: JSON) -> Result<Person> {
        let name = value["name"].string
        let age = value["age"].int
        let isMarried = value["spouse"].bool
        
        return mapAll(name, age, isMarried, Person.create)
    }
}

extension Person {
    private static func create(name: String, age: Int, spouse: Bool) -> Person {
        return self.init(name: name, age: age, spouse: spouse)
    }
}