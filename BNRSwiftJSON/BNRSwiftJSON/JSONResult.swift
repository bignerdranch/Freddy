//
//  JSONResult.swift
//  Test
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation
import Result

extension NSError: ErrorType {}

/**
    A newtype for Result<JSON> that provides additional properties for extracting typed JSON data.
*/
public struct JSONResult {
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

// MARK: - JSONResult Computed Properties

public extension JSONResult {
    /**
        Retrieves an `Array` of `JSONValue`s from the given `Result`.  If the target value's type inside of the `JSONValue` instance does not match `Array`, this property returns `.Failure` with an appropriate `error`.
    */
    var array: Result<[JSON]> {
        return bind { jsonValue in
            if let array = jsonValue.array {
                return Result(success: array)
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: "Array"))
            }
        }
    }
    
    /**
        Retrieves a `Dictionary` `JSONValue`s from the given `Result`.  If the target value's type inside of the `JSONValue` instance does not match `Dictionary`, this property returns `.Failure` with an appropriate `error`.
    */
    var dictionary: Result<[String: JSON]> {
        return bind { jsonValue in
            if let dict = jsonValue.dictionary {
                return Result(success: dict)
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: "Dictionary"))
            }
        }
    }
    
    /**
        Retrieves a `Double` from the `Result`.  If the target value's type inside of the `JSONValue` instance does not match `Double`, this property returns `.Failure` with an appropriate `error`.
    */
    var number: Result<Double> {
        return bind { jsonValue in
            if let num = jsonValue.number {
                return Result(success: num)
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Double.self))
            }
        }
    }
    
    /**
        Retrieves a `String` from the `Result`.  If the target value's type inside of the `JSONValue` instance does not match `String`, this property returns `.Failure` with an appropriate `error`.
    */
    var string: Result<String> {
        return bind { jsonValue in
            if let str = jsonValue.string {
                return Result(success: str)
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: String.self))
            }
        }
    }
    
    /**
        Retrieves a `Bool` from the `Result`.  If the target value's type inside of the `JSONValue` instance does not match `Bool`, this property returns `.Failure` with an appropriate `error`.
    */
    var bool: Result<Bool> {
        return bind { jsonValue in
            if let b = jsonValue.bool {
                return Result(success: b)
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Bool.self))
            }
        }
    }
    
    /**
        Retrieves an `Int` from the `Result`.  If the target value's type inside of the `JSONValue` instance does not match `Int`, this property returns `.Failure` with an appropriate `error`.
    */
    var int: Result<Int> {
        return bind { jsonValue in
            if let i = jsonValue.int {
                return Result(success: i)
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Int.self))
            }
        }
    }

    /**
        Retrieves `Null` from the `Result`. If the target value's type inside of the `JSONValue` instance does not match `Null`, this property returns `.Failure` with an appropriate `error`.
    */
    var null: Result<()> {
        return bind { jsonValue in
            if jsonValue.isNull {
                return Result(success: ())
            } else {
                return Result(failure: jsonValue.makeError(JSON.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: Int.self))
            }
        }
    }
}

// MARK: - Subscript JSONResult

public extension JSONResult {
    subscript(key: String) -> JSONResult {
        return bind { jsonValue in
            return jsonValue[key]
        }
    }
    
    subscript(index: Int) -> JSONResult {
        return bind { jsonValue in
            return jsonValue[index]
        }
    }
}

// MARK: - Additional Result functions

/**
    A function to collect `Result` instances into an array of `T` in the `.Success` case.

    :param: results An array of `Result<T>`: `[Result<T>]`.

    :returns: A `Result<[T]>` such that all successes are collected within an array of the `.Success` case.
*/
public func collectResults<T>(results: [Result<T>]) -> Result<[T]> {
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
public func splitResult<U, T>(result: Result<[U]>, f: U -> Result<T>) -> (successes: [T], failures: [ErrorType]) {
    var successes = [T]()
    var failures = [ErrorType]()
    switch result {
    case .Success(let results):
        for result in results.value {
            let res = f(result)
            switch res {
            case .Success(let r):
                successes.append(r.value)
            case .Failure(let error):
                failures.append(error)
            }
        }
    case .Failure(let error):
        failures.append(error)
    }
    return (successes, failures)
}