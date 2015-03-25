//
//  JSONValueResult.swift
//  Test
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation

/**
    An enum to handle binding from `JSONValue`s to `JSONValueResult`s to eliminte ugly `?`s when chaining.
*/
public enum JSONValueResult {
    case Success(JSONValue)
    case Failure(NSError)
    
    /**
        A method to `bind` a case's associated value to an instance of `JSONValueResult`.
    
        :param: f A closure to specify the binding.
    
        :returns: An instance of `JSONValueResult` containing the assigned `JSONValue` in the `.Value` case's associated value.
    */
    public func bind(f: JSONValue -> JSONValueResult) -> JSONValueResult {
        switch self {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let jsonValue):
            return f(jsonValue)
        }
    }
    
    /**
        A method to `bind` a `JSONValue` to an instance of `Result`.
    
        :param: f A closure to specify the binding.
    
        :returns: A `Result` containing the assigned `JSONValue` in the `.Value` case's associated value.
    */
    public func bind<T>(f: JSONValue -> Result<T>) -> Result<T> {
        switch self {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let jsonValue):
            return f(jsonValue)
        }
    }
}

// MARK: - JSONValueResult Computed Properties

public extension JSONValueResult {
    /**
        Retrieves an `Array` of `JSONValue`s from the given `JSONValueResult`.  If the target value's type inside of the `JSONValue` instance does not match `Array`, this property returns `nil`.
    */
    var array: Result<[JSONValue]> {
        return bind { json in
            if let array = json.array {
                return .Success(Box(array))
            } else {
                return .Failure(json.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: "Array"))
            }
        }
    }
    
    /**
        Retrieves a `Dictionary` `JSONValue`s from the given `JSONValueResult`.  If the target value's type inside of the `JSONValue` instance does not match `Dictionary`, this property returns `nil`.
    */
    var dictionary: Result<[String: JSONValue]> {
        return bind { json in
            if let dict = json.dictionary {
                return .Success(Box(dict))
            } else {
                return .Failure(json.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: "Dictionary"))
            }
        }
    }
    
    /**
        Retrieves a `Double` from the `JSONValueResult`.  If the target value's type inside of the `JSONValue` instance does not match `Double`, this property returns `nil`.
    */
    var number: Result<Double> {
        return bind { json in
            if let num = json.number {
                return .Success(Box(num))
            } else {
                return .Failure(json.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Double.self))
            }
        }
    }
    
    /**
        Retrieves a `String` from the `JSONValueResult`.  If the target value's type inside of the `JSONValue` instance does not match `String`, this property returns `nil`.
    */
    var string: Result<String> {
        return bind { json in
            if let str = json.string {
                return .Success(Box(str))
            } else {
                return .Failure(json.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: String.self))
            }
        }
    }
    
    /**
        Retrieves a `Bool` from the `JSONValueResult`.  If the target value's type inside of the `JSONValue` instance does not match `Bool`, this property returns `nil`.
    */
    var bool: Result<Bool> {
        return bind { json in
            if let b = json.bool {
                return .Success(Box(b))
            } else {
                return .Failure(json.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Bool.self))
            }
        }
    }
    
    /**
        Retrieves an `Int` from the `JSONValueResult`.  If the target value's type inside of the `JSONValue` instance does not match `Int`, this property returns `nil`.
    */
    var int: Result<Int> {
        return bind { json in
            if let i = json.int {
                return .Success(Box(i))
            } else {
                return .Failure(json.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Int.self))
            }
        }
    }
}

// MARK: - Subscript JSONValueResult

public extension JSONValueResult {
    subscript(key: String) -> JSONValueResult {
        return bind { jsonValue in
            return jsonValue[key]
        }
    }
    
    subscript(index: Int) -> JSONValueResult {
        return bind { jsonValue in
            return jsonValue[index]
        }
    }
}