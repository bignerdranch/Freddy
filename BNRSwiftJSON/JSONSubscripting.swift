//
//  JSONSubscripting.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 8/15/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation

/// A protocol representing known paths to a descendant of a `JSON` structure.
///
/// Do not declare new conformances to this protocol; they will not be
/// respected.
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

    /// Retrieves a `[JSON]` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Array` of `JSON` elements
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Array`.
    public func array(path: JSONPathType...) throws -> [JSON] {
        return try memberAtPath(path) { $0.array }
    }

    /// Retrieves a `[String: JSON]` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Dictionary`.
    public func dictionary(path: JSONPathType...) throws -> [Swift.String: JSON] {
        return try memberAtPath(path) { $0.dictionary }
    }

    /// Retrieves a `Double` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A floating-point `Double`
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Double`.
    public func double(path: JSONPathType...) throws -> Swift.Double {
        return try memberAtPath(path) { $0.double }
    }

    /// Retrieves an `Int` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A numeric `Int`
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Int`.
    public func int(path: JSONPathType...) throws -> Swift.Int {
        return try memberAtPath(path) { $0.int }
    }

    /// Retrieves a `String` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A textual `String`
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `String`.
    public func string(path: JSONPathType...) throws -> Swift.String {
        return try memberAtPath(path) { $0.string }
    }

    /// Retrieves a `Bool` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A truthy `Bool`
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Bool`.
    public func bool(path: JSONPathType...) throws -> Swift.Bool {
        return try memberAtPath(path) { $0.bool }
    }

    /// Confirms a null value exists at a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - throws:
    ///   * `JSON.Error.KeyNotFound`: A given `String` key does not exist
    ///     inside a descendant `JSON` dictionary.
    ///   * `JSON.Error.IndexOutOfBounds`: A given `Int` index is outside the
    ///     bounds of a descendant `JSON` array.
    ///   * `JSON.Error.UnexpectedSubscript`: A given subscript cannot be used
    ///     with the corresponding `JSON` value.
    ///   * `JSON.Error.TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Null`.
    public func isNull(path: JSONPathType...) throws {
        return try memberAtPath(path) { $0.isNull ? () : nil }
    }

}
