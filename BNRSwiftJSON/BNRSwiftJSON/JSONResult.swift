//
//  JSONResult.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Result

/**
    A newtype for Result<JSON> that provides additional properties for extracting typed JSON data.
*/
public struct JSONResult: Equatable {
    private let r: Result<JSON, NSError>

    internal static func success(success: JSON) -> JSONResult {
        return JSONResult(Result.success(success))
    }

    internal static func failure(error: NSError) -> JSONResult {
        return JSONResult(Result.failure(error))
    }

    internal init(_ result: Result<JSON, NSError>) {
        self.r = result
    }

    private func flatMap(f: JSON -> JSONResult) -> JSONResult {
        return JSONResult(r.flatMap { value in f(value).r })
    }

    private func flatMap<T>(f: JSON -> Result<T, NSError>) -> Result<T, NSError> {
        return r.flatMap(f)
    }

    /**
        Returns `true` if the target's underlying `Result` is in the `.Success` case.
    */
    public var isSuccess: Bool {
        return r.value != nil
    }

    /**
        Returns `true` if the target's underlying `Result` is in the `.Failure` case.
    */
    public var isFailure: Bool {
        return r.error != nil
    }
}

// MARK: - Serialize JSONResult

public extension JSONResult {
    /**
        A function to serialize an instance to NSData.
    
        :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData, NSError> {
        return flatMap { $0.serialize() }
    }
}

// MARK: - JSONResult Computed Properties

public extension JSONResult {
    private func convertType<T>(problem: String, _ f: (JSON) -> T?) -> Result<T, NSError> {
        return flatMap { json in
            if let converted = f(json) {
                return Result.success(converted)
            } else {
                return Result.failure(JSON.makeError(JSON.ErrorCode.TypeNotConvertible, problem: problem))
            }
        }
    }

    /**
        Retrieves an `Array` of `JSON`s from the given `Result`.  If the target value's type inside of the `JSON` instance does not match `Array`, this property returns `.Failure` with an appropriate `error`.
    */
    var array: Result<[JSON], NSError> {
        return convertType("Array", { $0.array })
    }
    
    /**
        Retrieves a `Dictionary` `JSON`s from the given `Result`.  If the target value's type inside of the `JSON` instance does not match `Dictionary`, this property returns `.Failure` with an appropriate `error`.
    */
    var dictionary: Result<[String: JSON], NSError> {
        return convertType("Dictionary", { $0.dictionary })
    }
    
    /**
        Retrieves a `Double` from the `Result`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `.Failure` with an appropriate `error`.
    */
    var double: Result<Double, NSError> {
        return convertType("Double", { $0.double })
    }

    /**
        Retrieves an `Int` from the `Result`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `.Failure` with an appropriate `error`.  Otherwise, any fractional components are discarded to return a success value.
    */
    var int: Result<Int, NSError> {
        return convertType("Int", { $0.int })
    }

    /**
        Retrieves a `String` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `String`, this property returns `.Failure` with an appropriate `error`.
    */
    var string: Result<String, NSError> {
        return convertType("String", { $0.string })
    }
    
    /**
        Retrieves a `Bool` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `Bool`, this property returns `.Failure` with an appropriate `error`.
    */
    var bool: Result<Bool, NSError> {
        return convertType("Bool", { $0.bool })
    }

    /**
        Retrieves `Null` from the `Result`. If the target value's type inside of the `JSON` instance does not match `Null`, this property returns `.Failure` with an appropriate `error`.
    */
    var null: Result<(), NSError> {
        return convertType("Null", { $0.isNull ? () : nil })
    }
}

// MARK: - Subscript JSONResult

public extension JSONResult {
    subscript(key: String) -> JSONResult {
        return flatMap { JSON in
            return JSON[key]
        }
    }
    
    subscript(index: Int) -> JSONResult {
        return flatMap { JSON in
            return JSON[index]
        }
    }
}

// MARK: - Test Equality

public func ==(lhs: JSONResult, rhs: JSONResult) -> Bool {
    return lhs.r == rhs.r
}
