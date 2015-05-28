//
//  CardUtilities.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/21/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

import Foundation
import BNRSwiftJSON
import Result

func optional<A>(input: Result<A>) -> Result<A?> {
    switch input {
    case .Success(let box):
        return Result(success: Optional.Some(box.value))
    case .Failure(let error as NSError) where error.domain == JSON.errorDomain && error.code == JSON.ErrorCode.KeyNotFound.rawValue:
        return Result(success: Optional.None)
    case .Failure(let error):
        return Result(failure: error)
    }
}

func fallback<A>(input: Result<A>, @autoclosure getter: () -> A) -> Result<A> {
    switch input {
    case .Success:
        return input
    case .Failure(let error as NSError) where error.domain == JSON.errorDomain && error.code == JSON.ErrorCode.KeyNotFound.rawValue:
        return Result(success: getter())
    case .Failure(_):
        return input
    }
}

func arrayOf<A>(input: JSONResult, getter: JSONResult -> Result<A>) -> Result<[A]> {
    return input.array.bind { (arr) -> Result<[A]> in
        collectAllSuccesses(lazy(arr).map({
            getter(JSONResult(success: $0))
        }))
    }
}

func arrayOf<T: JSONDecodable>(json: JSONResult) -> Result<[T]> {
    return json.array.bind {
        collectAllSuccesses(lazy($0).map(T.createWithJSON))
    }
}
