//
//  JSONParsing.swift
//  Freddy
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation

// MARK: - Deserialize JSON

/// Protocol describing a backend parser that can produce `JSON` from `NSData`.
public protocol JSONParserType {

    /// Creates an instance of `JSON` from `NSData`.
    static func createJSONFromData(data: NSData) throws -> JSON

}

extension JSON {

    /// Create `JSON` from UTF-8 `data`. By default, parses using the
    /// Swift-native `JSONParser` backend.
    public init(data: NSData, usingParser parser: JSONParserType.Type = JSONParser.self) throws {
        self = try parser.createJSONFromData(data)
    }

}

// MARK: - NSJSONSerialization

extension NSJSONSerialization: JSONParserType {

    // MARK: Decode NSData

    /// Use the built-in, Objective-C based JSON parser to create `JSON`.
    /// - parameter data: An instance of `NSData`.
    /// - returns: An instance of `JSON`.
    /// - throws: An error that may arise if the `NSData` cannot be parsed into an object.
    public static func createJSONFromData(data: NSData) throws -> JSON {
        return JSON(try NSJSONSerialization.JSONObjectWithData(data, options: []))
    }

}

// MARK: - Serialize JSON

extension JSON {

    /// Attempt to serialize `JSON` into an `NSData`.
    /// - returns: A byte-stream containing the `JSON` ready for wire transfer.
    /// - throws: Errors that arise from `NSJSONSerialization`.
    /// - see: Foundation.NSJSONSerialization
    public func serialize() throws -> NSData {
        let obj: AnyObject = toNSJSONSerializationObject()
        return try NSJSONSerialization.dataWithJSONObject(obj, options: [])
    }

    /// A function to help with the serialization of `JSON`.
    /// - returns: An `AnyObject` suitable for `NSJSONSerialization`'s use.
    private func toNSJSONSerializationObject() -> AnyObject {
        switch self {
        case .Array(let jsonArray):
            return jsonArray.map { $0.toNSJSONSerializationObject() }
        case .Dictionary(let jsonDictionary):
            var cocoaDictionary = Swift.Dictionary<Swift.String, AnyObject>(minimumCapacity: jsonDictionary.count)
            for (key, json) in jsonDictionary {
                cocoaDictionary[key] = json.toNSJSONSerializationObject()
            }
            return cocoaDictionary
        case .String(let str):
            return str
        case .Double(let num):
            return num
        case .Int(let int):
            return int
        case .Bool(let b):
            return b
        case .Null:
            return NSNull()
        }

    }
}
