//
//  JSONSubscripting.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 8/15/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation

public protocol JSONPathType {}

extension String: JSONPathType {}
extension Int: JSONPathType    {}

extension JSON {

    private func memberAtPath<T>(path: [JSONPathType], @noescape getter: JSON -> T?) throws -> T {
        let descendant = try path.reduce(self) { json, path in
            switch (json, path) {
            case let (.Dictionary(dict), key as Swift.String):
                guard let next = dict[key] else {
                    throw Error.KeyNotFound(key: key)
                }
                return next
            case let (.Array(array), index as Swift.Int):
                guard array.startIndex.advancedBy(index, limit: array.endIndex) != array.endIndex else {
                    throw Error.IndexOutOfBounds(index: index)
                }
                return array[index]
            case (_, let badSubscript):
                throw Error.UnexpectedSubscript(type: badSubscript.dynamicType)
            }
        }

        guard let child = getter(descendant) else {
            throw Error.ValueNotConvertible(type: T.self)
        }

        return child
    }

    // MARK: Simple member unpacking

    public func array(path: JSONPathType...) throws -> [JSON] {
        return try memberAtPath(path) { $0.array }
    }

    public func dictionary(path: JSONPathType...) throws -> [Swift.String: JSON] {
        return try memberAtPath(path) { $0.dictionary }
    }

    public func double(path: JSONPathType...) throws -> Swift.Double {
        return try memberAtPath(path) { $0.double }
    }

    public func int(path: JSONPathType...) throws -> Swift.Int {
        return try memberAtPath(path) { $0.int }
    }

    public func string(path: JSONPathType...) throws -> Swift.String {
        return try memberAtPath(path) { $0.string }
    }

    public func bool(path: JSONPathType...) throws -> Swift.Bool {
        return try memberAtPath(path) { $0.bool }
    }

    public func isNull(path: JSONPathType...) throws {
        return try memberAtPath(path) { $0.isNull ? () : nil }
    }

}
