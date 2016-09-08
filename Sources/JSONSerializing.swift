// Copyright (C) 2016 Big Nerd Ranch, Inc. Licensed under the MIT license WITHOUT ANY WARRANTY.

import Foundation

// MARK: - Serialize JSON

extension JSON {

    /// Attempt to serialize `JSON` into an `NSData`.
    /// - returns: A byte-stream containing the `JSON` ready for wire transfer.
    /// - throws: Errors that arise from `NSJSONSerialization`.
    /// - see: Foundation.NSJSONSerialization
    public func serialize() throws -> Data {
        return try JSONSerialization.data(withJSONObject: toNSJSONSerializationValue(), options: [])
    }

    /// A function to help with the serialization of `JSON`.
    /// - returns: An `Any` suitable for `NSJSONSerialization`'s use.
    private func toNSJSONSerializationValue() -> Any {
        switch self {
        case .Array(let jsonArray):
            return jsonArray.map { $0.toNSJSONSerializationValue() }
        case .Dictionary(let jsonDictionary):
            var cocoaDictionary = Swift.Dictionary<Swift.String, Any>(minimumCapacity: jsonDictionary.count)
            for (key, json) in jsonDictionary {
                cocoaDictionary[key] = json.toNSJSONSerializationValue()
            }
            return cocoaDictionary
        case .String(let str):
            return str
        case .Double(let num):
            return NSNumber(value: num)
        case .Int(let int):
            return NSNumber(value: int)
        case .Bool(let b):
            return NSNumber(value: b)
        case .null:
            return NSNull()
        }

    }
}
