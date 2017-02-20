// Copyright (C) 2016 Big Nerd Ranch, Inc. Licensed under the MIT license WITHOUT ANY WARRANTY.

import Foundation

// MARK: - Serialize Options

/// An `OptionSet` used to represent the different options available for serializing `JSON` with `null` values.
/// * `.nullSkipsKey` - Skip keys with `null` values so the key is not included
/// in the serialized json
public struct SerializeOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Skip keys with `null` values so the key is not included
    /// in the serialized json
    public static let nullSkipsKey = SerializeOptions(rawValue: 1 << 0)
}

// MARK: - Serialize JSON

extension JSON {

    /// Attempt to serialize `JSON` into an `Data`.
    /// - parameter options: SerializeOptions that control what should be done with keys that have values that are `null` when serializing the JSON
    /// - returns: A byte-stream containing the `JSON` ready for wire transfer.
    /// - throws: Errors that arise from `JSONSerialization`.
    /// - see: Foundation.JSONSerialization
    public func serialize(options: SerializeOptions = []) throws -> Data {
        return try JSONSerialization.data(withJSONObject: toJSONSerializationValue(options: options), options: [])
    }
    
    /// Attempt to serialize `JSON` into a `String`.
    /// - parameter options: SerializeOptions that control what should be done with keys that have values that are `null` when serializing the JSON
    /// - returns: A `String` containing the `JSON`.
    /// - throws: A `JSON.Error.StringSerializationError` or errors that arise from `JSONSerialization`.
    /// - see: Foundation.JSONSerialization
    public func serializeString(options: SerializeOptions = []) throws -> String {
        let data = try self.serialize(options: options)
        guard let json = String(data: data, encoding: String.Encoding.utf8) else {
            throw Error.stringSerializationError
        }
        return json
    }

    /// A function to help with the serialization of `JSON`.
    /// - parameter options: SerializeOptions that control what should be done with keys that have values that are `null` when serializing the JSON
    /// - returns: An `Any` suitable for `JSONSerialization`'s use.
    private func toJSONSerializationValue(options: SerializeOptions = []) -> Any {
        switch self {
        case .array(let jsonArray):
            return jsonArray.map { $0.toJSONSerializationValue() }
        case .dictionary(let jsonDictionary):
            var cocoaDictionary = Swift.Dictionary<Swift.String, Any>(minimumCapacity: jsonDictionary.count)
            for (key, json) in jsonDictionary {
                
                if json != .null || (json == .null && !options.contains(.nullSkipsKey)) {
                    cocoaDictionary[key] = json.toJSONSerializationValue()
                }
            }
            return cocoaDictionary
        case .string(let str):
            return str
        case .double(let num):
            return NSNumber(value: num)
        case .int(let int):
            return NSNumber(value: int)
        case .bool(let b):
            return NSNumber(value: b)
        case .null:
            return NSNull()
        }

    }
}
