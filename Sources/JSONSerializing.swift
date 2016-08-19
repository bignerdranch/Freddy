// Copyright (C) 2016 Big Nerd Ranch, Inc. Licensed under the MIT license WITHOUT ANY WARRANTY.

import Foundation

// MARK: - Serialize JSON

extension JSON {

    /// Attempt to serialize `JSON` into an `NSData`.
    /// - returns: A byte-stream containing the `JSON` ready for wire transfer.
    /// - throws: Errors that arise from `NSJSONSerialization`.
    /// - see: Foundation.NSJSONSerialization
    public func serialize() throws -> Data {
        let obj: AnyObject = toNSJSONSerializationObject()
        return try JSONSerialization.data(withJSONObject: obj, options: [])
    }

    /// A function to help with the serialization of `JSON`.
    /// - returns: An `AnyObject` suitable for `NSJSONSerialization`'s use.
    private func toNSJSONSerializationObject() -> AnyObject {
        switch self {
        case .Array(let jsonArray):
            return jsonArray.map { $0.toNSJSONSerializationObject() } as AnyObject
        case .Dictionary(let jsonDictionary):
            var cocoaDictionary = Swift.Dictionary<Swift.String, AnyObject>(minimumCapacity: jsonDictionary.count)
            for (key, json) in jsonDictionary {
                cocoaDictionary[key] = json.toNSJSONSerializationObject()
            }
            return cocoaDictionary as AnyObject
        case .String(let str):
            return str as AnyObject
        case .Double(let num):
            return num as AnyObject
        case .Int(let int):
            return int as AnyObject
        case .Bool(let b):
            return NSNumber(value: b)
        case .null:
            return NSNull()
        }

    }
}
