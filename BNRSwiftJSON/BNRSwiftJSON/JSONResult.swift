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
        Retrieves a `Double` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `Double`, this property returns `.Failure` with an appropriate `error`.
    */
    var number: Result<Double> {
        return convertType("Double", { $0.number })
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
        Retrieves an `Int` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `Int`, this property returns `.Failure` with an appropriate `error`.
    */
    var int: Result<Int> {
        return convertType("Int", { $0.int })
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

    :param: results An array of `Result<T>`: `[Result<T>]`.

    :returns: A `Result<[T]>` such that all successes are collected within an array of the `.Success` case.
*/
public func collectAllSuccesses<T>(results: [Result<T>]) -> Result<[T]> {
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

/**
    A function to `map` the `Result` value into a function call.

    :param: r1 The `Result`.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,U>(r1: Result<T1>, f: (T1) -> U) -> Result<U> {
    return r1.map { s1 in
        f(s1)
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r2 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,U>(r1: Result<T1>, r2: Result<T2>, f: (T1,T2) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.map { s2 in
            f(s1, s2)
        }
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r3 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, f: (T1,T2,T3) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.bind { s2 in
            r3.map { s3 in
                f(s1, s2, s3)
            }
        }
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r4 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, f: (T1,T2,T3,T4) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.bind { s2 in
            r3.bind { s3 in
                r4.map { s4 in
                    f(s1, s2, s3, s4)
                }
            }
        }
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r5 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, f: (T1,T2,T3,T4,T5) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.bind { s2 in
            r3.bind { s3 in
                r4.bind { s4 in
                    r5.map { s5 in
                        f(s1, s2, s3, s4, s5)
                    }
                }
            }
        }
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r6 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,T6,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, f: (T1,T2,T3,T4,T5,T6) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.bind { s2 in
            r3.bind { s3 in
                r4.bind { s4 in
                    r5.bind { s5 in
                        r6.map { s6 in
                            f(s1, s2, s3, s4, s5, s6)
                        }
                    }
                }
            }
        }
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r7 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,T6,T7,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, r7: Result<T7>, f: (T1,T2,T3,T4,T5,T6,T7) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.bind { s2 in
            r3.bind { s3 in
                r4.bind { s4 in
                    r5.bind { s5 in
                        r6.bind { s6 in
                            r7.map { s7 in
                                f(s1, s2, s3, s4, s5, s6, s7)
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
    A function to `map` all of the `Result` values into a single function call.

    :param: r1...r8 The `Result`s.
    :param: f The function to call.

    :returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,T6,T7,T8,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, r7: Result<T7>, r8: Result<T8>, f: (T1,T2,T3,T4,T5,T6,T7,T8) -> U) -> Result<U> {
    return r1.bind { s1 in
        r2.bind { s2 in
            r3.bind { s3 in
                r4.bind { s4 in
                    r5.bind { s5 in
                        r6.bind { s6 in
                            r7.bind { s7 in
                                r8.map { s8 in
                                    f(s1, s2, s3, s4, s5, s6, s7, s8)
                                }
                            }
                        }
                    }
                }
            }
        }
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
