//
//  ResultFlatMapping.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 6/3/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Result

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0 The `Result`.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,U, Error>(r0: Result<T0, Error>, _ f: (T0) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in f(s0) }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r1 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ f: (T0,T1) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1) { f(s0, $0) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r2 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ f: (T0,T1,T2) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2) { f(s0, $0, $1) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r3 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ f: (T0,T1,T2,T3) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3) { f(s0, $0, $1, $2) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r4 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ f: (T0,T1,T2,T3,T4) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4) { f(s0, $0, $1, $2, $3) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r5 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ f: (T0,T1,T2,T3,T4,T5) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5) { f(s0, $0, $1, $2, $3, $4) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r6 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6) { f(s0, $0, $1, $2, $3, $4, $5) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r7 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7) { f(s0, $0, $1, $2, $3, $4, $5, $6) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r8 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r9 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r10 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ r10: Result<T10, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r11 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ r10: Result<T10, Error>, _ r11: Result<T11, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r12 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ r10: Result<T10, Error>, _ r11: Result<T11, Error>, _ r12: Result<T12, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r13 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ r10: Result<T10, Error>, _ r11: Result<T11, Error>, _ r12: Result<T12, Error>, _ r13: Result<T13, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r14 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ r10: Result<T10, Error>, _ r11: Result<T11, Error>, _ r12: Result<T12, Error>, _ r13: Result<T13, Error>, _ r14: Result<T14, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) } }
}

/**
A function to `flatMap` all of the `Result` values into a single function call.

:param: r0...r15 The `Result`s.
:param: f The function to call.

:returns: A `Result<U, Error>`.
*/
public func flatMapAll<T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,U, Error>(r0: Result<T0, Error>, _ r1: Result<T1, Error>, _ r2: Result<T2, Error>, _ r3: Result<T3, Error>, _ r4: Result<T4, Error>, _ r5: Result<T5, Error>, _ r6: Result<T6, Error>, _ r7: Result<T7, Error>, _ r8: Result<T8, Error>, _ r9: Result<T9, Error>, _ r10: Result<T10, Error>, _ r11: Result<T11, Error>, _ r12: Result<T12, Error>, _ r13: Result<T13, Error>, _ r14: Result<T14, Error>, _ r15: Result<T15, Error>, _ f: (T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15) -> Result<U, Error>) -> Result<U, Error> {
    return r0.flatMap { s0 in flatMapAll(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15) { f(s0, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) } }
}
