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

// MARK: - Errors

extension JSON {

    public enum Error: ErrorType {
        /// The given index is out of bounds for the JSON array.
        case IndexOutOfBounds(Swift.Int)
        /// The given key was not found in the JSON object.
        case KeyNotFound(Swift.String)
        /// The JSON is not subscriptable with
        case UnexpectedSubscript(JSONPathType.Type)
        /// Unexpected JSON was found that is not convertible to the given type.
        case TypeNotConvertible(Any.Type)
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
        case .Array(let arr):       return Swift.String(arr)
        case .Dictionary(let dict): return Swift.String(dict)
        case .String(let string):   return string
        case .Double(let double):   return Swift.String(double)
        case .Int(let int):         return Swift.String(int)
        case .Bool(let bool):       return Swift.String(bool)
        case .Null:                 return "null"
        }
    }

}
