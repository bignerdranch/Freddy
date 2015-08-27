//
//  JSONResult.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import Result

public typealias JSONResult = Result<JSON, JSON.Error>

// MARK: - Serialize JSON Result

public extension ResultType where Value == JSON {
    /**
        A function to serialize an instance to NSData.
    
        :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData, NSError> {
        return analysis(ifSuccess: {
            do {
                return .Success(try $0.serialize())
            } catch {
                return .Failure(error as NSError)
            }
        }, ifFailure: { error in
            .Failure(error as NSError)
        })
    }
}

// MARK: - JSON Result Computed Properties

public extension ResultType where Value == JSON, Error == JSON.Error {
    private func convertType<T>(@noescape getter: JSON -> T?) -> Result<T, JSON.Error> {
        return analysis(ifSuccess: { json in
            Result(getter(json), failWith: JSON.Error.TypeNotConvertible(T.self))
        }, ifFailure: Result.Failure)
    }

    /**
        Retrieves an `Array` of `JSON`s from the given `Result`.  If the target value's type inside of the `JSON` instance does not match `Array`, this property returns `.Failure` with an appropriate `error`.
    */
    var array: Result<[JSON], JSON.Error> {
        return convertType { $0.array }
    }
    
    /**
        Retrieves a `Dictionary` `JSON`s from the given `Result`.  If the target value's type inside of the `JSON` instance does not match `Dictionary`, this property returns `.Failure` with an appropriate `error`.
    */
    var dictionary: Result<[String: JSON], JSON.Error> {
        return convertType { $0.dictionary }
    }
    
    /**
        Retrieves a `Double` from the `Result`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `.Failure` with an appropriate `error`.
    */
    var double: Result<Double, JSON.Error> {
        return convertType { $0.double }
    }

    /**
        Retrieves an `Int` from the `Result`.  If the target value's type inside of the `JSON` instance is not a numeric type, this property returns `.Failure` with an appropriate `error`.  Otherwise, any fractional components are discarded to return a success value.
    */
    var int: Result<Int, JSON.Error> {
        return convertType { $0.int }
    }

    /**
        Retrieves a `String` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `String`, this property returns `.Failure` with an appropriate `error`.
    */
    var string: Result<String, JSON.Error> {
        return convertType { $0.string }
    }
    
    /**
        Retrieves a `Bool` from the `Result`.  If the target value's type inside of the `JSON` instance does not match `Bool`, this property returns `.Failure` with an appropriate `error`.
    */
    var bool: Result<Bool, JSON.Error> {
        return convertType { $0.bool }
    }

    /**
        Retrieves `Null` from the `Result`. If the target value's type inside of the `JSON` instance does not match `Null`, this property returns `.Failure` with an appropriate `error`.
    */
    var null: Result<Void, JSON.Error> {
        return convertType { $0.isNull ? () : nil }
    }
}
