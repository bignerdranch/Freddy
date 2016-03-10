//
//  JSONSubscripting.swift
//  Freddy
//
//  Created by James Campbell on 25/02/2016.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

// MARK: - Subscripting core

extension JSON: JSONSource {
    
    public func jsonValue() -> JSON {
        return self
    }
    
    public func isNull() -> Swift.Bool {
        return  self == .Null
    }
    
    public func valueForPathFragment(fragment: JSONPathType, detectNull: Swift.Bool) throws -> JSONSource {
        switch self {
        case .Null where detectNull:
            throw JSONSubscriptError.SubscriptIntoNull(fragment)
        case let .Dictionary(dict):
            return try fragment.valueInDictionary(dict)
        case let .Array(array):
            return try fragment.valueInArray(array)
        default:
            throw JSON.Error.UnexpectedSubscript(type: fragment.dynamicType)
        }
    }
    
    public func valueAtPath(path: [JSONPathType], detectNull: Swift.Bool = false) throws -> JSONSource {
        var result: JSONSource = self
        for fragment in path {
            result = try result.valueForPathFragment(fragment, detectNull: detectNull)
        }
        return result
    }
    
}

// MARK: - Subscripting operator

extension JSON {
    
    subscript(key: Swift.String) -> JSONSource? {
        return try? valueForPathFragment(key, detectNull: false)
    }
    
    subscript(index: Swift.Int) -> JSONSource? {
        return try? valueForPathFragment(index, detectNull: false)
    }
    
}
