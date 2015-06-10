//
//  ResultFlatMapping.swift
//  Freddy
//
//  Created by John Gallagher on 6/3/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Result

/**
A function to `flatMap` the `Result` value into a function call.

:param: r1 The `Result`.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,U, Error>(r1: Result<T1, Error>, f: (T1) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in
        f(s1)
    }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r2 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, f: (T1,T2) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2) { f(s1, $0) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r3 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,T3,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, r3: Result<T3, Error>, f: (T1,T2,T3) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2, r3) { f(s1, $0, $1) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r4 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,T3,T4,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, r3: Result<T3, Error>, r4: Result<T4, Error>, f: (T1,T2,T3,T4) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2, r3, r4) { f(s1, $0, $1, $2) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r5 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,T3,T4,T5,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, r3: Result<T3, Error>, r4: Result<T4, Error>, r5: Result<T5, Error>, f: (T1,T2,T3,T4,T5) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2, r3, r4, r5) { f(s1, $0, $1, $2, $3) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r6 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,T3,T4,T5,T6,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, r3: Result<T3, Error>, r4: Result<T4, Error>, r5: Result<T5, Error>, r6: Result<T6, Error>, f: (T1,T2,T3,T4,T5,T6) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2, r3, r4, r5, r6) { f(s1, $0, $1, $2, $3, $4) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r7 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,T3,T4,T5,T6,T7,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, r3: Result<T3, Error>, r4: Result<T4, Error>, r5: Result<T5, Error>, r6: Result<T6, Error>, r7: Result<T7, Error>, f: (T1,T2,T3,T4,T5,T6,T7) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2, r3, r4, r5, r6, r7) { f(s1, $0, $1, $2, $3, $4, $5) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r1...r8 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T1,T2,T3,T4,T5,T6,T7,T8,U, Error>(r1: Result<T1, Error>, r2: Result<T2, Error>, r3: Result<T3, Error>, r4: Result<T4, Error>, r5: Result<T5, Error>, r6: Result<T6, Error>, r7: Result<T7, Error>, r8: Result<T8, Error>, f: (T1,T2,T3,T4,T5,T6,T7,T8) -> Result<U, Error>) -> Result<U, Error> {
    return r1.flatMap { s1 in flatMapAll(r2, r3, r4, r5, r6, r7, r8) { f(s1, $0, $1, $2, $3, $4, $5, $6) } }
}
