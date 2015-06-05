//
//  JSONResult.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Result

extension NSError: ErrorType {}

/**
    A newtype for Result<JSON> that provides additional properties for extracting typed JSON data.
*/
public struct JSONResult: Equatable {
    private let r: Result<JSON>

    internal init(success: JSON) {
        r = Result(success: success)
    }

    internal init(failure: ErrorType) {
        r = Result(failure: failure)
    }

    private init(r: Result<JSON>) {
        self.r = r
    }

    private func bind(f: JSON -> JSONResult) -> JSONResult {
        return JSONResult(r: r.bind { value in f(value).r })
    }

    private func bind<T>(f: JSON -> Result<T>) -> Result<T> {
        return r.bind(f)
    }

    /**
        Returns `true` if the target's underlying `Result` is in the `.Success` case.
    */
    public var isSuccess: Bool {
        return r.isSuccess
    }

    /**
        Returns `true` if the target's underlying `Result` is in the `.Failure` case.
    */
    public var isFailure: Bool {
        return r.isFailure
    }
}

// MARK: - Serialize JSONResult

public extension JSONResult {
    /**
        A function to serialize an instance to NSData.
    
        :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData> {
        return bind { $0.serialize() }
    }
}

// MARK: - JSONResult Computed Properties

public extension JSONResult {
    private func convertType<T>(problem: String, _ f: (JSON) -> T?) -> Result<T> {
        return bind { json in
            if let converted = f(json) {
                return Result(success: converted)
            } else {
                return Result(failure: JSON.makeError(JSON.ErrorCode.TypeNotConvertible, problem: problem))
            }
        }
    }


    /**
        Retrieves an `Array` of `JSON`s from the given `Result`.  If the target value's type inside of the `JSON` instance does not match `Array`, this property returns `.Failure` with an appropriate `error`.
    */
    var array: Result<[JSON]> {
        return convertType("Array", { $0.array })
    }
    
    /**
        Retrieves a `Dictionary` `JSON`s from the given `Result`.  If the target value's type inside of the `JSON` instance does not match `Dictionary`, this property returns `.Failure` with an appropriate `error`.
    */
    var dictionary: Result<[String: JSON]> {
        return convertType("Dictionary", { $0.dictionary })
    }
    
    /**
        Retrieves a `Double` from the `Result`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `.Failure` with an appropriate `error`.
    */
    var double: Result<Double> {
        return convertType("Double", { $0.double })
    }

    /**
        Retrieves an `Int` from the `Result`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `.Failure` with an appropriate `error`.  Otherwise, any fractional components are discarded to return a success value.
    */
    var int: Result<Int> {
        return convertType("Int", { $0.int })
    }

    /**
        Retrieves a `String` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `String`, this property returns `.Failure` with an appropriate `error`.
    */
    var string: Result<String> {
        return convertType("String", { $0.string })
    }
    
    /**
        Retrieves a `Bool` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `Bool`, this property returns `.Failure` with an appropriate `error`.
    */
    var bool: Result<Bool> {
        return convertType("Bool", { $0.bool })
    }

    /**
        Retrieves `Null` from the `Result`. If the target value's type inside of the `JSON` instance does not match `Null`, this property returns `.Failure` with an appropriate `error`.
    */
    var null: Result<()> {
        return convertType("Null", { $0.isNull ? () : nil })
    }
}

// MARK: - Subscript JSONResult

public extension JSONResult {
    subscript(key: String) -> JSONResult {
        return bind { JSON in
            return JSON[key]
        }
    }
    
    subscript(index: Int) -> JSONResult {
        return bind { JSON in
            return JSON[index]
        }
    }
}

// MARK: - Additional Result functions

/**
    A function to collect `Result` instances into an array of `T` in the `.Success` case.

    :param: results Any sequence of `Result<T>`: `[Result<T>]`.

    :returns: A `Result<[T]>` such that all successes are collected within an array of the `.Success` case.
*/
public func collectAllSuccesses<T, S: SequenceType where S.Generator.Element == Result<T>>(results: S) -> Result<[T]> {
    var successes = [T]()
    for result in results {
        switch result {
        case .Success(let res):
            successes.append(res.value)
        case .Failure(let error):
            return Result(failure: error)
        }
    }
    return Result(success: successes)
}

/**
    A function to break a `Result` with an array of type `[U]` into a tuple of `successes` and `failures`.

    :param: result The `Result<[U]>`.
    :param: f The function to be used to create the array given to the `successes` member of the tuple.

    :returns: A tuple of `successes` and `failures`.
*/
public func splitResult<U, T>(result: Result<[U]>, f: U -> Result<T>) -> Result<(successes: [T], failures: [ErrorType])> {
    var successes = [T]()
    var failures = [ErrorType]()
    return result.bind { results in
        for result in results {
            switch f(result) {
            case .Success(let r):
                successes.append(r.value)
            case .Failure(let error):
                failures.append(error)
            }
        }
        return Result(success:(successes, failures))
    }
}

// MARK: - Test Equality

public func ==(lhs: JSONResult, rhs: JSONResult) -> Bool {
    switch (lhs.r, rhs.r) {
    case (.Failure(let error), _):
        return false
    case (_, .Failure(let error)):
        return false
    case (.Success(let lhsValue), .Success(let rhsValue)):
        return lhsValue.value == rhsValue.value
    default:
        return false
    }
}
