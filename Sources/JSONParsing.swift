//
//  JSONParsing.swift
//  Freddy
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation

// MARK: - Deserialize JSON

/// Protocol describing a backend parser that can produce `JSON` from `Data`.
public protocol JSONParserType {

    /// Creates an instance of `JSON` from `Data`.
    /// - parameter data: An instance of `Data` to use to create `JSON`.
    /// - throws: An error that may arise from calling `JSONObjectWithData(_:options:)` on `NSJSONSerialization` with the given data.
    /// - returns: An instance of `JSON`.
    static func createJSON(from data: Data) throws -> JSON

}

extension JSON {

    /// Create `JSON` from UTF-8 `data`. By default, parses using the
    /// Swift-native `JSONParser` backend.
    public init(data: Data, usingParser parser: JSONParserType.Type = JSONParser.self) throws {
        self = try parser.createJSON(from: data)
    }

    /// Create `JSON` from UTF-8 `string`.
    public init(jsonString: Swift.String, usingParser parser: JSONParserType.Type = JSONParser.self) throws {
        self = try parser.createJSON(from: jsonString.data(using: Swift.String.Encoding.utf8) ?? Data())
    }
}

// MARK: - NSJSONSerialization

extension JSONSerialization: JSONParserType {

    // MARK: Decode Data

    /// Use the built-in, Objective-C based JSON parser to create `JSON`.
    /// - parameter data: An instance of `Data`.
    /// - returns: An instance of `JSON`.
    /// - throws: An error that may arise if the `Data` cannot be parsed into an object.
    public static func createJSON(from data: Data) throws -> JSON {
        return makeJSON(with: try JSONSerialization.jsonObject(with: data, options: []))
    }

    // MARK: Make JSON

    /// Makes a `JSON` object by matching its argument to a case in the `JSON` enum.
    /// - parameter object: The instance of `Any` returned from serializing the JSON.
    /// - returns: An instance of `JSON` matching the JSON given to the function.
    public static func makeJSON(with object: Any) -> JSON {
        #if !swift(>=3.2) && (os(macOS) || os(iOS) || os(macOS) || os(tvOS))
            if let n = object as? NSNumber {
                let numberType = CFNumberGetType(n)
                switch numberType {
                case .charType:
                    return .bool(n.boolValue)

                case .shortType, .intType, .longType, .cfIndexType, .nsIntegerType, .sInt8Type, .sInt16Type, .sInt32Type:
                    return .int(n.intValue)

                default:
                    return .double(n.doubleValue)
                }
            }
        #endif

        switch object {
        case let n as Bool:
            return .bool(n)

        case let n as Int:
            return .int(n)

        case let n as Double:
            return .double(n)

        case let n as NSNumber:
            return .double(n.doubleValue)

        case let arr as [Any]:
            return makeJSONArray(arr)

        case let dict as [String: Any]:
            return makeJSONDictionary(dict)

        case let s as String:
            return .string(s)

        default:
            return .null
        }
    }

    // MARK: Make a JSON Array

    /// Makes a `JSON` array from the object passed in.
    /// - parameter jsonArray: The array to transform into a `JSON`.
    /// - returns: An instance of `JSON` matching the array.
    private static func makeJSONArray(_ jsonArray: [Any]) -> JSON {
        return .array(jsonArray.map(makeJSON))
    }

    // MARK: Make a JSON Dictionary

    /// Makes a `JSON` dictionary from the Cocoa dictionary passed in.
    /// - parameter jsonDict: The dictionary to transform into `JSON`.
    /// - returns: An instance of `JSON` matching the dictionary.
    private static func makeJSONDictionary(_ jsonDict: [Swift.String: Any]) -> JSON {
        return JSON(jsonDict.lazy.map { pair in
            (pair.key, makeJSON(with: pair.value))
        })
    }

}
