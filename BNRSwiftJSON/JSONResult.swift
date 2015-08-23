//
//  JSONResult.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import Result

public typealias JSONResult = Result<JSON, NSError>

// MARK: - Serialize JSON Result

public extension ResultType where Value == JSON {
    /**
        A function to serialize an instance to NSData.
    
        :returns: A `Result` with `NSData` in the `.Success` case, `.Failure` with an `NSError` otherwise.
    */
    public func serialize() -> Result<NSData, NSError> {
        return analysis(ifSuccess: {
            $0.serialize()
        }, ifFailure: { error in
            .Failure(error as NSError)
        })
    }
}

// MARK: - JSON Result Computed Properties

public extension ResultType where Value == JSON {
    private func convertType<T>(problem: String, @noescape _ getter: JSON -> T?) -> Result<T, NSError> {
        return analysis(ifSuccess: { json in
            if let converted = getter(json) {
                return .Success(converted)
            } else {
                return .Failure(JSON.makeError(JSON.ErrorCode.TypeNotConvertible, problem: problem))
            }
        }, ifFailure: { error in
            .Failure(error as NSError)
        })
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

public extension ResultType where Value == JSON {
    subscript(key: String) -> JSONResult {
        return analysis(ifSuccess: { JSON in
            JSON[key]
        }, ifFailure: { error in
            .Failure(error as NSError)
        })
    }
    
    subscript(index: Int) -> JSONResult {
        return analysis(ifSuccess: { JSON in
            JSON[index]
        }, ifFailure: { error in
            .Failure(error as NSError)
        })
    }
}
