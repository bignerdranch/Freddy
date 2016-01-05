//
//  JSONEncodable.swift
//  Freddy
//
//  Created by Matthew Mathias on 1/4/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

/// A protocol to facilitate encoding and decoding of `JSON`.
public protocol JSONEncodable {
    /// Converts an instance of a conforming type to `JSON`.
    /// - returns: An instance of `JSON`.
    /// - Note: If conforming to `JSONEncodable` with a custom type of your own, you should return an instance of 
    /// `JSON.Dictionary`.
    func encodeToJSON() -> JSON
}

extension Array where Element: JSONEncodable {
    /// Converts an instance of `Array` whose elements conform to `JSONEncodable` to `JSON`.
    /// - returns: An instance of `JSON` where the enum case is `.Array`.
    public func encodeToJSON() -> JSON {
        let arrayOfJSON = self.map { $0.encodeToJSON() }
        return .Array(arrayOfJSON)
    }
}

extension Dictionary where Value: JSONEncodable {
    /// Converts an instance of `Dictionary` whose values conform to `JSONEncodable` to `JSON`.  The keys in the resulting
    /// `JSON.Dictionary` will be of type `String`.
    /// - returns: An instance of `JSON` where the enum case is `.Dictionary`.
    public func encodeToJSON() -> JSON {
        var jsonDictionary = [String: JSON]()
        
        for (k, v) in self {
            let key = String(k)
            jsonDictionary[key] = v.encodeToJSON()
        }
        
        return .Dictionary(jsonDictionary)
    }
}

extension Int: JSONEncodable {
    /// Converts an instance of a conforming type to `JSON`.
    /// - returns: An instance of `JSON` where the enum case is `.Int`.
    public func encodeToJSON() -> JSON {
        return .Int(self)
    }
}

extension Double: JSONEncodable {
    /// Converts an instance of a conforming type to `JSON`.
    /// - returns: An instance of `JSON` where the enum case is `.Double`.
    public func encodeToJSON() -> JSON {
        return .Double(self)
    }
}

extension String: JSONEncodable {
    /// Converts an instance of a conforming type to `JSON`.
    /// - returns: An instance of `JSON` where the enum case is `.String`.
    public func encodeToJSON() -> JSON {
        return .String(self)
    }
}

extension Bool: JSONEncodable {
    /// Converts an instance of a conforming type to `JSON`.
    /// - returns: An instance of `JSON` where the enum case is `.Bool`.
    public func encodeToJSON() -> JSON {
        return .Bool(self)
    }
}