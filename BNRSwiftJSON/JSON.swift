//
//  JSON.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/17/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import Result

/**
    An enum to describe the structure of JSON.
*/
public enum JSON {
    case Array([JSON])
    case Dictionary([Swift.String: JSON])
    case Double(Swift.Double)
    case Int(Swift.Int)
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
            var parser = JSONParser(utf8Data: data)
            switch parser.parse() {
            case .Success(let json):
                return .Success(json)
            case .Failure(let error):
                return .Failure(.CouldNotParse(error))
            }

        case .NSJSONSerialization:
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                return .Success(makeJSON(json))
            } catch {
                return .Failure(.CouldNotParse(error))
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
    
    // MARK: - Serialize JSON
    /**
        Attempt to serialize `JSON` into an `NSData`.

        :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData, NSError> {
        let obj: AnyObject = toNSJSONSerializationObject()
        do {
            let result = try NSJSONSerialization.dataWithJSONObject(obj, options: [])
            return .Success(result)
        } catch {
            return .Failure(error as NSError)
        }
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
        Retrieves a `Double` from the `JSON`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `nil`.
    */
    var double: Swift.Double? {
        switch self {
        case .Double(let dbl):
            return dbl
        case .Int(let int):
            return Swift.Double(int)
        case .Bool(let bool):
            return bool ? 1 : 0
        default:
            return nil
        }
    }
    
    /**
        Retrieves an `Int` from the `JSON`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `nil`.  Any fractional parts contained by the `JSON` instance will be discarded.
    */
    var int: Swift.Int? {
        switch self {
        case .Double(let dbl):
            return Swift.Int(dbl)
        case .Int(let int):
            return int
        case .Bool(let bool):
            return bool ? 1 : 0
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
                    return .Success(obj)
                } else {
                    return .Failure(Error.KeyNotFound(key))
                }
            default:
                return .Failure(Error.UnexpectedSubscript(Swift.String.self))
            }
        }
    }
    
    subscript(index: Swift.Int) -> JSONResult {
        get {
            switch self {
            case .Array(let jsonArray):
                if index <= jsonArray.count - 1 {
                    return .Success(jsonArray[index])
                } else {
                    return .Failure(Error.IndexOutOfBounds(index))
                }
            default:
                return .Failure(Error.UnexpectedSubscript(Swift.Int.self))
            }

        }
    }
}

// MARK: - Errors

extension JSON {

    public enum Error: ErrorType {
        /// The given index is out of bounds for the JSON array.
        case IndexOutOfBounds(Swift.Int)
        /// The given key was not found in the JSON object.
        case KeyNotFound(Swift.String)
        /// The JSON is not subscriptable with
        case UnexpectedSubscript(Any.Type)
        /// Unexpected JSON was found that is not convertible to the given type.
        case TypeNotConvertible(Any.Type)
        /// An error occurred while parsing JSON text.
        case CouldNotParse(ErrorType)
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
    case (.Double(let dubL), .Double(let dubR)):
        return dubL == dubR
    case (.Double(let dubL), .Int(let intR)):
        return dubL == Double(intR)
    case (.Int(let intL), .Int(let intR)):
        return intL == intR
    case (.Int(let intL), .Double(let dubR)):
        return Double(intL) == dubR
    case (.Bool(let bL), .Bool(let bR)):
        return bL == bR
    case (.Null, .Null):
        return true
    default:
        return false
    }
}

extension JSON: Equatable {}

// MARK: - Printing

extension JSON: CustomStringConvertible {

    public var description: Swift.String {
        switch self {
        case .String(let str): return str
        case .Double(let double): return Swift.String(double)
        case .Int(let int): return Swift.String(int)
        case .Bool(let bool): return Swift.String(bool)
        case .Null: return "null"
        default:
            return serialize().map {
                NSString(data: $0, encoding: NSUTF8StringEncoding) as! Swift.String
            } ?? "unknown"
        }
    }

}
