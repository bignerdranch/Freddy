//
//  ResultSequences.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 6/3/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Result

/**
A function to collect `Result` instances into an array of `T` in the `.Success` case.

:param: results Any sequence of `Result<T>`.

:returns: A `Result<[T], Error>` such that all successes are collected within an array of the `.Success` case.
*/
public func collectAllSuccesses<T, Error, S: SequenceType where S.Generator.Element == Result<T, Error>>(results: S) -> Result<[T], Error> {
    var successes = [T]()
    for result in results {
        switch result {
        case .Success(let res):
            successes.append(res.value)
        case .Failure(let error):
            return Result.failure(error.value)
        }
    }
    return Result.success(successes)
}

/**
A function to break a `Result` containing a sequence into a tuple of `successes` and `failures`.

:param: result The `Result` possibly containing a sequence of `T`s.
:param: f The function to be used to create the array given to the `successes` member of the tuple.

:returns: If `result` is in the success case, returns a tuple of `successes` and `failures`. Otherwise,
returns the error currently in `result`.
*/
public func splitResult<T, U, Error, S: SequenceType where S.Generator.Element == T>(result: Result<S, Error>, f: T -> Result<U, Error>) -> Result<(successes: [U], failures: [Error]), Error> {
    return result.map { partitionResults(map($0, f)) }
}

/**
A function to partition an array of results into successes and failure.

:param: results Any sequence of `Result<T, Error>`.

:returns: A tuple of successes and failures.
*/
public func partitionResults<T, Error, S: SequenceType where S.Generator.Element == Result<T, Error>>(results: S) -> ([T], [Error]) {
    var successes = [T]()
    var failures = [Error]()

    for result in results {
        switch result {
        case let .Success(boxed): successes.append(boxed.value)
        case let .Failure(error): failures.append(error.value)
        }
    }

    return (successes, failures)
}
