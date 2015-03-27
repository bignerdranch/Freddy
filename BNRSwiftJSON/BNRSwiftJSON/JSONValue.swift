//
//  JSONValue.swift
//  JSONParser
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation

/**
    An enum to describe the structure of JSON.
*/
public enum JSONValue {
    case JSONArray([JSONValue])
    case JSONDictionary([String: JSONValue])
    case JSONNumber(Double)
    case JSONString(String)
    case JSONBool(Int)
    case JSONNull()
    
    // MARK: Decode NSData
    /**
        Creates an optional instance of `JSONValue` from `NSData`.
    
        :param: data The instance of `NSData` from the web service.
    
        :returns: An optional instance of `JSONValue`.
    */
    public static func createJSONValueFrom(data: NSData) -> JSONValueResult {
        var error: NSError?
        let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
        
        if let obj: AnyObject = jsonObject {
            return .Success(makeJSONValue(obj))
        } else {
            let error = NSError(domain: "com.bignerdranch.swift-json", code: JSONValue.BNRSwiftJSONErrorCode.CouldNotParseJSON.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Could not parse `NSData`."])
            return .Failure(error)
        }
    }
    
    // MARK: Make JSON Value
    /**
        Makes a `JSONValue` object by matching its argument to a case in the `JSONValue` enum.
    
        :param: object The instance of `AnyObject` returned from serializing the JSON.
    
        :returns: An instance of `JSONValue` matching the JSON given to the function.
    */
    private static func makeJSONValue(object: AnyObject) -> JSONValue {
        switch object {
        case let arr as [AnyObject]:
            return makeJSONValueArray(arr)
        case let dict as [Swift.String: AnyObject]:
            return makeJSONValueDictionary(dict)
        case let n as Double:
            return .JSONNumber(n)
        case let s as Swift.String:
            return .JSONString(s)
        case let b as Int:
            return .JSONBool(b)
        default:
            return .JSONNull()
        }
    }
    
    // MARK: Make a JSON Value Array
    /**
        Makes a `JSONValue` array from the object passed in.
    
        :param: jsonArray The array to transform into a `JSONValue`.
    
        :returns: An instance of `JSONValue` matching the array.
    */
    private static func makeJSONValueArray(jsonArray: [AnyObject]) -> JSONValue {
        var items = [JSONValue]()
        for item in jsonArray {
            let value = makeJSONValue(item)
            items.append(value)
        }
        return .JSONArray(items)
    }
    
    // MARK: Make a JSONValue Dictionary
    /**
        Makes a `JSONValue` dictionary from the `JSONValue` object passed in.
    
        :param: jsonDict The dictionary to transform into a `JSValue`.
    
        :returns: An instance of `JSONValue` matching the dictionary.
    */
    private static func makeJSONValueDictionary(jsonDict: [String: AnyObject]) -> JSONValue {
        var dict = [String: JSONValue]()
        for (key, value) in jsonDict {
            dict[key as String] = makeJSONValue(value)
        }
        return .JSONDictionary(dict)
    }
}

// MARK: - Computed properties for the JSONValue

public extension JSONValue {
    /**
        Retrieves a `Dictionary` from the given `JSONValue`.  If the target value's type inside of the `JSONValue` instance does not match `Dictionary`, this property returns `nil`.
    */
    var dictionary: [Swift.String: JSONValue]? {
        switch self {
        case .JSONDictionary(let dict):
            return dict
        default:
            return nil
        }
    }
    
    /**
        Retrieves an `Array` of `JSONValue`s from the given `JSONValue`.  If the target value's type inside of the `JSONValue` instance does not match `Array`, this property returns `nil`.
    */
    var array: [JSONValue]? {
        switch self {
        case .JSONArray(let value):
            return value
        default:
            return nil
        }
    }
    
    /**
        Retrieves a `String` from the `JSONValue`.  If the target value's type inside of the `JSONValue` instance does not match `String`, this property returns `nil`.
    */
    var string: String? {
        switch self {
        case .JSONString(let s):
            return s
        default:
            return nil
        }
    }
    
    /**
        Retrieves a `Double` from the `JSONValue`.  If the target value's type inside of the `JSONValue` instance does not match `Double`, this property returns `nil`.
    */
    var number: Double? {
        switch self {
        case .JSONNumber(let dub):
            return Double(dub)
        default:
            return nil
        }
    }
    
    /**
        Retrieves an `Int` from the `JSONValue`.  If the target value's type inside of the `JSONValue` instance does not match `Int`, this property returns `nil`.
    */
    var int: Int? {
        switch self {
        case .JSONNumber(let num):
            return Int(num)
        default:
            return nil
        }
    }
    
    /**
        Retrieves a `Bool` from the `JSONValue`.  If the target value's type inside of the `JSONValue` instance does not match `Bool`, this property returns `nil`.
    */
    var bool: Bool? {
        switch self {
        case .JSONNumber(let b):
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
}

// MARK: - Subscript JSONValue

public extension JSONValue {
    subscript(key: String) -> JSONValueResult {
        get {
            switch self {
            case .JSONDictionary(let jsonDict):
                if let obj = jsonDict[key] {
                    return .Success(obj)
                } else {
                    return .Failure(makeError(BNRSwiftJSONErrorCode.KeyNotFound, problem: key))
                }
            default:
                return .Failure(makeError(BNRSwiftJSONErrorCode.UnexpectedType, problem: key))
            }
        }
    }
    
    subscript(index: Int) -> JSONValueResult {
        get {
            switch self {
            case .JSONArray(let jsonArray):
                if index <= jsonArray.count - 1 {
                    return .Success(jsonArray[index])
                } else {
                    return .Failure(makeError(BNRSwiftJSONErrorCode.IndexOutOfBounds, problem: index))
                }
            default:
                return .Failure(makeError(BNRSwiftJSONErrorCode.UnexpectedType, problem: index))
            }
        }
    }
}

// MARK: - NilLiteralConvertible

public extension JSONValue {
    init(nilLiteral: ()) {
        self.init(nilLiteral: ())
    }
}

// MARK: - Errors

public extension JSONValue {
    var errorDomain: String {
        return "com.bignerdranch.swift-json"
    }
    
    enum BNRSwiftJSONErrorCode: Int {
        case IndexOutOfBounds, KeyNotFound, UnexpectedType, TypeNotConvertible, CouldNotParseJSON
    }
}

// MARK: - Make Errors

extension JSONValue {
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
            let errorDict = [NSLocalizedFailureReasonErrorKey: "Could not parse JSON. Check the `NSData` instance."]
            return NSError(domain: errorDomain, code: reason.rawValue, userInfo: errorDict)
        }
    }
}