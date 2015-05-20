//
//  JSON.swift
//  JSONParser
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation
import Result

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

    /// Enum describing the available backend parsers that can produce `JSONResult`s from `NSData`.
    public enum Parser {
        /// A pure Swift JSON parser. This parser is much faster than the NSJSONSerialization-based
        /// parser (due to the overhead of having to dynamically cast the Objective-C objects to
        /// determine their type); however, it is much newer and has restrictions that the
        /// NSJSONSerialization parser does not. Two restrictions in particular are that it requires
        /// UTF8 data as input and it does not allow trailing commas in arrays or dictionaries.
        case PureSwift

        /// Use the built-in, Objective-C based JSON parser.
        case NSJSONSerialization
    }

    // MARK: Decode NSData
    /**
        Creates an optional instance of `JSON` from `NSData`.
    
        :param: data The instance of `NSData` from the web service.
    
        :returns: An optional instance of `JSON`.
    */
    public static func createJSONFrom(data: NSData, usingParser parser: Parser = .PureSwift) -> JSONResult {
        switch parser {
        case .PureSwift:
            switch JSONFromUTF8Data(data) {
            case .Success(let boxed):
                return JSONResult(success: boxed.value)
            case .Failure(let error):
                return JSONResult(failure: error)
            }

        case .NSJSONSerialization:
            var error: NSError?
            let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
            
            if let obj: AnyObject = jsonObject {
                return JSONResult(success: makeJSON(obj))
            } else {
                return JSONResult(failure: error!)
            }
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
        case let n as NSNumber:
            switch n {
            case _ where CFNumberGetType(n) == .CharType || CFGetTypeID(n) == CFBooleanGetTypeID():
                return .Bool(n.boolValue)
            default:
                return .Number(n.doubleValue)
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
        var dict: [Swift.String: JSON] = [:]
        for (key, value) in jsonDict {
            dict[key as Swift.String] = makeJSON(value)
        }
        return .Dictionary(dict)
    }
    
    // MARK: - Serialize JSON
    /**
        Attempt to serialize `JSON` into an `NSData`.

        :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData> {
        let obj: AnyObject = toNSJSONSerializationObject()
        var error: NSError?
        if let data = NSJSONSerialization.dataWithJSONObject(obj, options: nil, error: &error) {
            return Result(success: data)
        } else {
            return Result(failure: error!)
        }
    }

    /**
        A function to help with the serialization of `JSON`.

        :returns: An `AnyObject` suitable for `NSJSONSerialization`'s use.
    */
    private func toNSJSONSerializationObject() -> AnyObject {
        switch self {
        case .Array(let jsonArray):
            return map(jsonArray) { $0.toNSJSONSerializationObject() }
        case .Dictionary(let jsonDictionary):
            var dict: [Swift.String: AnyObject] = Swift.Dictionary(minimumCapacity: jsonDictionary.count)
            for (key, value) in jsonDictionary {
                dict[key] = value.toNSJSONSerializationObject()
            }
            return dict
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
        case .Bool(let b):
            return b
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
                    return JSONResult(failure: JSON.makeError(ErrorCode.KeyNotFound, problem: key))
                }
            default:
                return JSONResult(failure: JSON.makeError(ErrorCode.UnexpectedType, problem: key))
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
                    return JSONResult(failure: JSON.makeError(ErrorCode.IndexOutOfBounds, problem: index))
                }
            default:
                return JSONResult(failure: JSON.makeError(ErrorCode.UnexpectedType, problem: index))
            }
        }
    }
}

// MARK: - Errors

public extension JSON {
    static let errorDomain = "com.bignerdranch.BNRSwiftJSON"
    
    enum ErrorCode: Int {
        case IndexOutOfBounds, KeyNotFound, UnexpectedType, TypeNotConvertible, CouldNotParseJSON
    }
}

// MARK: - Make Errors

extension JSON {
    static func makeError<T>(reason: ErrorCode, problem: T) -> NSError {
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
            let errorDict = [NSLocalizedFailureReasonErrorKey: "Could not parse `JSON`: \(problem)"]
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
