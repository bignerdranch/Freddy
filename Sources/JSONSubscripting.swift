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
    
    func jsonValue() -> JSON {
        return self
    }
    
    func isNull() -> Swift.Bool {
        return  self == .Null
    }
    
    func valueForPathFragment(fragment: JSONPathType, detectNull: Swift.Bool) throws -> JSONSource {
        switch self {
        case .Null where detectNull:
            throw JSONSubscriptError.SubscriptIntoNull(fragment)
        case let .Dictionary(dict):
            return try fragment.valueInDictionary(dict)
        case let .Array(array):
            return try fragment.valueInArray(array)
        default:
            throw JSONError.UnexpectedSubscript(type: fragment.dynamicType)
        }
    }
    
    func valueAtPath(path: [JSONPathType], detectNull: Swift.Bool = false) throws -> JSONSource {
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