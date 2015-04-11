//
//  JSON.swift
//  JSONParser
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation
import Swift

/**
    An enum to describe the structure of JSON.
*/
public enum JSON: Equatable {
    case Array([JSON])
    case Dictionary([Swift.String: JSON])
    case Number(Double)
    case String(Swift.String)
    case Bool(Swift.Bool)
    case Null
    
    // MARK: Decode NSData
    /**
        Creates an optional instance of `JSON` from `NSData`.
    
        :param: data The instance of `NSData` from the web service.
    
        :returns: An optional instance of `JSON`.
    */
    public static func createJSONFrom(data: NSData) -> JSONResult {
        let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
        
        if let obj: AnyObject = jsonObject {
            return JSONResult(success: makeJSON(obj))
        } else {
            let error = NSError(domain: "com.bignerdranch.BNRSwiftJSON", code: JSON.BNRSwiftJSONErrorCode.CouldNotParseJSON.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Could not parse `NSData`."])
            return JSONResult(failure: error)
        }
    }
    
    // MARK: Make JSON
    /**
        Makes a `JSON` object by matching its argument to a case in the `JSON` enum.
    
        :param: object The instance of `AnyObject` returned from serializing the JSON.
    
        :returns: An instance of `JSON` matching the JSON given to the function.
    */
    private static func makeJSON(object: AnyObject) -> JSON {
        switch object {
        case let arr as [AnyObject]:
            return makeJSONArray(arr)
        case let dict as [Swift.String: AnyObject]:
            return makeJSONDictionary(dict)
        case let n as Double:
            return .Number(n)
        case let s as Swift.String:
            return .String(s)
        case let b as Swift.Bool:
            return .Bool(b)
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
        var dict: [Swift.String: JSON] = [:]
        for (key, value) in jsonDict {
            dict[key as Swift.String] = makeJSON(value)
        }
        return .Dictionary(dict)
    }
    
    // MARK: - Serialize JSON
    /**
        Serializes `JSON` into an `AnyObject`.
    
        :returns: An instance of `AnyObject`.
    */
    internal func serializeJSON() -> AnyObject {
        switch self {
        case .Array(let jsonArray):
            return map(jsonArray) { $0.serializeJSON() }
        case .Dictionary(let jsonDictionary):
            return serializeJSONDictionary(jsonDictionary)
        case .String(let str):
            return str
        case .Number(let num):
            return num
        case .Bool(let b):
            return b
        case .Null:
            return NSNull()
        }
    }
    
    /**
        A function to help with the serialization of `JSON` into a `Dictionary`.
    
        :param: jsonDict A `Dictionary` of type `[Swift.String: JSON]` to serialize.
    
        :returns: A `Dictionary` of type `[Swift.String: AnyObject]`.
    */
    private func serializeJSONDictionary(jsonDict: [Swift.String: JSON]) -> [Swift.String: AnyObject] {
        var dict: [Swift.String: AnyObject] = Swift.Dictionary(minimumCapacity: jsonDict.count)
        for (key, value) in jsonDict {
            dict[key] = value.serializeJSON()
        }
        return dict
    }
}

// MARK: - Computed properties for the JSON

public extension JSON {
    /**
        Retrieves a `Dictionary` from the given `JSON`.  If the target value's type inside of the `JSON` instance does not match `Dictionary`, this property returns `nil`.
    */
    var dictionary: [Swift.String: JSON]? {
        switch self {
        case .Dictionary(let dict):
            return dict
        default:
            return nil
        }
    }
    
    /**
        Retrieves an `Array` of `JSON`s from the given `JSON`.  If the target value's type inside of the `JSON` instance does not match `Array`, this property returns `nil`.
    */
    var array: [JSON]? {
        switch self {
        case .Array(let value):
            return value
        default:
            return nil
        }
    }
    
    /**
        Retrieves a `String` from the `JSON`.  If the target value's type inside of the `JSON` instance does not match `String`, this property returns `nil`.
    */
    var string: Swift.String? {
        switch self {
        case .String(let s):
            return s
        default:
            return nil
        }
    }
    
    /**
        Retrieves a `Double` from the `JSON`.  If the target value's type inside of the `JSON` instance does not match `Double`, this property returns `nil`.
    */
    var number: Double? {
        switch self {
        case .Number(let dub):
            return Double(dub)
        default:
            return nil
        }
    }
    
    /**
        Retrieves an `Int` from the `JSON`.  If the target value's type inside of the `JSON` instance does not match `Int`, this property returns `nil`.
    */
    var int: Int? {
        switch self {
        case .Number(let num):
            return Int(num)
        default:
            return nil
        }
    }
    
    /**
        Retrieves a `Bool` from the `JSON`.  If the target value's type inside of the `JSON` instance does not match `Bool`, this property returns `nil`.
    */
    var bool: Swift.Bool? {
        switch self {
        case .Number(let b):
            switch b {
            case 0:
                return false
            case 1:
                return true
            default:
                return nil
            }
        default:
            return nil
        }
    }

    /**
        Returns true if the target's type is `Null`.
    */
    var isNull: Swift.Bool {
        switch self {
        case .Null:
            return true
        default:
            return false
        }
    }
}

// MARK: - Subscript JSON

public extension JSON {
    subscript(key: Swift.String) -> JSONResult {
        get {
            switch self {
            case .Dictionary(let jsonDict):
                if let obj = jsonDict[key] {
                    return JSONResult(success: obj)
                } else {
                    return JSONResult(failure: makeError(BNRSwiftJSONErrorCode.KeyNotFound, problem: key))
                }
            default:
                return JSONResult(failure: makeError(BNRSwiftJSONErrorCode.UnexpectedType, problem: key))
            }
        }
    }
    
    subscript(index: Int) -> JSONResult {
        get {
            switch self {
            case .Array(let jsonArray):
                if index <= jsonArray.count - 1 {
                    return JSONResult(success: jsonArray[index])
                } else {
                    return JSONResult(failure: makeError(BNRSwiftJSONErrorCode.IndexOutOfBounds, problem: index))
                }
            default:
                return JSONResult(failure: makeError(BNRSwiftJSONErrorCode.UnexpectedType, problem: index))
            }
        }
    }
}

// MARK: - NilLiteralConvertible

extension JSON: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self.init(nilLiteral: ())
    }
}

// MARK: - Errors

public extension JSON {
    var errorDomain: Swift.String { return "com.bignerdranch.BNRSwiftJSON" }
    
    enum BNRSwiftJSONErrorCode: Int {
        case IndexOutOfBounds, KeyNotFound, UnexpectedType, TypeNotConvertible, CouldNotParseJSON, CouldNotSerializeJSON
    }
}

// MARK: - Make Errors

extension JSON {
    func makeError<T>(reason: BNRSwiftJSONErrorCode, problem: T) -> NSError {
        switch reason {
        case .IndexOutOfBounds:
            let errorDict = [NSLocalizedFailureReasonErrorKey: "`\(problem)` is out of bounds."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        case .KeyNotFound:
            let errorDict = [NSLocalizedFailureReasonErrorKey: "`\(problem)` is not a key within the JSON."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        case .UnexpectedType:
            let errorDict = [NSLocalizedFailureReasonErrorKey: "`\(self)` is not subscriptable with `\(problem)`."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        case .TypeNotConvertible:
            let errorDict = [NSLocalizedFailureReasonErrorKey: "Unexpected type. `\(self)` is not convertible to `\(problem)`."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        case .CouldNotParseJSON:
            let errorDict = [NSLocalizedFailureReasonErrorKey: "Could not parse `JSON`. Check the `NSData` instance."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        case .CouldNotSerializeJSON:
            let errorDict = [NSLocalizedFailureReasonErrorKey: "Could not serialize \(problem) into `NSData`. Check the `JSON` instance."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        }
    }
}

// MARK: - Test Equality

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs, rhs) {
    case (.Array(let arrL), .Array(let arrR)):
        return arrL == arrR
    case (.Dictionary(let dictL), .Dictionary(let dictR)):
        return dictL == dictR
    case (.String(let strL), .String(let strR)):
        return strL == strR
    case (.Number(let numL), .Number(let numR)):
        return numL == numR
    case (.Bool(let bL), .Bool(let bR)):
        return bL == bR
    case (.Null, .Null):
        return true
    default:
        return false
    }
}
