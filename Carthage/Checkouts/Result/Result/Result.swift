//
//  Result.swift
//  Result
//
//  Created by John Gallagher on 9/12/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation
import Box

public enum Result<T> {
    case Failure(ErrorType)

    // TODO: Get rid of Box hack at some point after 6.3
    case Success(Box<T>)

    public init(failure: ErrorType) {
        self = .Failure(failure)
    }

    public init(success: T) {
        self = .Success(Box(success))
    }

    public var successValue: T? {
        switch self {
        case let .Success(success): return success.value
        case .Failure: return nil
        }
    }

    public var failureValue: ErrorType? {
        switch self {
        case .Success: return nil
        case let .Failure(error): return error
        }
    }

    public var isSuccess: Bool {
        switch self {
        case .Success: return true
        case .Failure: return false
        }
    }

    public var isFailure: Bool {
        switch self {
        case .Success: return false
        case .Failure: return true
        }
    }

    public func map<U>(f: T -> U) -> Result<U> {
        switch self {
        case let .Failure(error): return .Failure(error)
        case let .Success(value): return .Success(Box(f(value.value)))
        }
    }

    public func bind<U>(f: T -> Result<U>) -> Result<U> {
        switch self {
        case let .Failure(error): return .Failure(error)
        case let .Success(value): return f(value.value)
        }
    }
}

extension Result: Printable {
    public var description: String {
        switch self {
        case let .Failure(error): return "Result.Failure(\(error))"
        case let .Success(value): return "Result.Success(\(value.value))"
        }
    }
}

public func partitionResults<T>(results: [Result<T>]) -> ([T], [ErrorType]) {
    var successes = [T]()
    var failures = [ErrorType]()

    for result in results {
        switch result {
        case let .Success(boxed): successes.append(boxed.value)
        case let .Failure(error): failures.append(error)
        }
    }

    return (successes, failures)
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
    return r1.bind { s1 in mapAll(r2) { f(s1, $0) } }
}

/**
A function to `map` all of the `Result` values into a single function call.

:param: r1...r3 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, f: (T1,T2,T3) -> U) -> Result<U> {
    return r1.bind { s1 in mapAll(r2, r3) { f(s1, $0, $1) } }
}

/**
A function to `map` all of the `Result` values into a single function call.

:param: r1...r4 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, f: (T1,T2,T3,T4) -> U) -> Result<U> {
    return r1.bind { s1 in mapAll(r2, r3, r4) { f(s1, $0, $1, $2) } }
}

/**
A function to `map` all of the `Result` values into a single function call.

:param: r1...r5 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, f: (T1,T2,T3,T4,T5) -> U) -> Result<U> {
    return r1.bind { s1 in mapAll(r2, r3, r4, r5) { f(s1, $0, $1, $2, $3) } }
}

/**
A function to `map` all of the `Result` values into a single function call.

:param: r1...r6 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,T6,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, f: (T1,T2,T3,T4,T5,T6) -> U) -> Result<U> {
    return r1.bind { s1 in mapAll(r2, r3, r4, r5, r6) { f(s1, $0, $1, $2, $3, $4) } }
}

/**
A function to `map` all of the `Result` values into a single function call.

:param: r1...r7 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,T6,T7,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, r7: Result<T7>, f: (T1,T2,T3,T4,T5,T6,T7) -> U) -> Result<U> {
    return r1.bind { s1 in mapAll(r2, r3, r4, r5, r6, r7) { f(s1, $0, $1, $2, $3, $4, $5) } }
}

/**
A function to `map` all of the `Result` values into a single function call.

:param: r1...r8 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func mapAll<T1,T2,T3,T4,T5,T6,T7,T8,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, r7: Result<T7>, r8: Result<T8>, f: (T1,T2,T3,T4,T5,T6,T7,T8) -> U) -> Result<U> {
    return r1.bind { s1 in mapAll(r2, r3, r4, r5, r6, r7, r8) { f(s1, $0, $1, $2, $3, $4, $5, $6) } }
}

/**
A function to `bind` the `Result` value into a function call.

:param: r1 The `Result`.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,U>(r1: Result<T1>, f: (T1) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in
        f(s1)
    }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r2 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,U>(r1: Result<T1>, r2: Result<T2>, f: (T1,T2) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2) { f(s1, $0) } }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r3 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,T3,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, f: (T1,T2,T3) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2, r3) { f(s1, $0, $1) } }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r4 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,T3,T4,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, f: (T1,T2,T3,T4) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2, r3, r4) { f(s1, $0, $1, $2) } }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r5 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,T3,T4,T5,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, f: (T1,T2,T3,T4,T5) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2, r3, r4, r5) { f(s1, $0, $1, $2, $3) } }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r6 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,T3,T4,T5,T6,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, f: (T1,T2,T3,T4,T5,T6) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2, r3, r4, r5, r6) { f(s1, $0, $1, $2, $3, $4) } }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r7 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,T3,T4,T5,T6,T7,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, r7: Result<T7>, f: (T1,T2,T3,T4,T5,T6,T7) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2, r3, r4, r5, r6, r7) { f(s1, $0, $1, $2, $3, $4, $5) } }
}

/**
A function to `bind` all of the `Result` values into a single function call.

:param: r1...r8 The `Result`s.
:param: f The function to call.

:returns: A `Result<U>`.
*/
public func bindAll<T1,T2,T3,T4,T5,T6,T7,T8,U>(r1: Result<T1>, r2: Result<T2>, r3: Result<T3>, r4: Result<T4>, r5: Result<T5>, r6: Result<T6>, r7: Result<T7>, r8: Result<T8>, f: (T1,T2,T3,T4,T5,T6,T7,T8) -> Result<U>) -> Result<U> {
    return r1.bind { s1 in bindAll(r2, r3, r4, r5, r6, r7, r8) { f(s1, $0, $1, $2, $3, $4, $5, $6) } }
}
