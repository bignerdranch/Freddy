//
//  JSONParsing.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation
import Result

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
    public static func createJSONFromData(data: NSData) throws -> JSON {
        return makeJSON(try NSJSONSerialization.JSONObjectWithData(data, options: []))
    }
    
    // MARK: Make JSON
    
    /**
    Makes a `JSON` object by matching its argument to a case in the `JSON` enum.
    
    :param: object The instance of `AnyObject` returned from serializing the JSON.
    
    :returns: An instance of `JSON` matching the JSON given to the function.
    */
    private static func makeJSON(object: AnyObject) -> JSON {
        switch object {
        case let n as NSNumber:
            switch n {
            case _ where CFNumberGetType(n) == .CharType || CFGetTypeID(n) == CFBooleanGetTypeID():
                return .Bool(n.boolValue)
            case _ where !CFNumberIsFloatType(n):
                return .Int(n.integerValue)
            default:
                return .Double(n.doubleValue)
            }
        case let arr as [AnyObject]:
            return makeJSONArray(arr)
        case let dict as [Swift.String: AnyObject]:
            return makeJSONDictionary(dict)
        case let s as Swift.String:
            return .String(s)
        default:
            return .Null
        }
    }
    
    // MARK: Make a JSON Array
    
    /**
    Makes a `JSON` array from the object passed in.
    
    :param: jsonArray The array to transform into a `JSON`.
    
    :returns: An instance of `JSON` matching the array.
    */
    private static func makeJSONArray(jsonArray: [AnyObject]) -> JSON {
        var items = [JSON]()
        for item in jsonArray {
            let value = makeJSON(item)
            items.append(value)
        }
        return .Array(items)
    }
    
    // MARK: Make a JSON Dictionary
    
    /**
    Makes a `JSON` dictionary from the `JSON` object passed in.
    
    :param: jsonDict The dictionary to transform into a `JSValue`.
    
    :returns: An instance of `JSON` matching the dictionary.
    */
    private static func makeJSONDictionary(jsonDict: [Swift.String: AnyObject]) -> JSON {
        return .Dictionary(jsonDict.map { makeJSON($1) })
    }
    
}

// MARK: - Serialize JSON

extension JSON {
    
    /**
    Attempt to serialize `JSON` into an `NSData`.
    
    :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData, NSError> {
        let obj: AnyObject = toNSJSONSerializationObject()
        return Result(try NSJSONSerialization.dataWithJSONObject(obj, options: []))
    }
    
    /**
    A function to help with the serialization of `JSON`.
    
    :returns: An `AnyObject` suitable for `NSJSONSerialization`'s use.
    */
    private func toNSJSONSerializationObject() -> AnyObject {
        switch self {
        case .Array(let jsonArray):
            return jsonArray.map { $0.toNSJSONSerializationObject() }
        case .Dictionary(let jsonDictionary):
            return jsonDictionary.map { $1.toNSJSONSerializationObject() } as [NSObject: AnyObject]
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
