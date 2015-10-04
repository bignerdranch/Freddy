//
//  JSONSubscripting.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 8/15/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation

// MARK: - JSON Path

/// A protocol representing known paths to a descendant of a `JSON` structure.
///
/// Do not declare new conformances to this protocol; they will not be
/// respected.
public protocol JSONPathType {}

extension String: JSONPathType {}
extension Int: JSONPathType    {}

// MARK: - Subscripting

extension JSON {

    // MARK: Native subscripting

    private enum SubscriptError: ErrorType {
        case SubscriptIntoNull(type: JSONPathType.Type)
    }

    private func descendantAtPath<Path: CollectionType where Path.Generator.Element == JSONPathType>(path: Path, detectNull: Swift.Bool = false) throws -> JSON {
        return try path.reduce(self) { json, path in
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
            case (.Null, let badSubscript) where detectNull:
                throw SubscriptError.SubscriptIntoNull(type: badSubscript.dynamicType)
            case (_, let badSubscript):
                throw Error.UnexpectedSubscript(type: badSubscript.dynamicType)
            }
        }
    }

    public subscript(key: Swift.String) -> JSON? {
        return try? descendantAtPath(CollectionOfOne(key))
    }

    public subscript(index: Swift.Int) -> JSON? {
        return try? descendantAtPath(CollectionOfOne(index))
    }

    // MARK: Simple member unpacking

    private func decodedAtPath<Decoded: JSONDecodable>(path: [JSONPathType], detectNull: Swift.Bool = false) throws -> Decoded {
        let json = try descendantAtPath(path, detectNull: detectNull)
        return try Decoded(json: json)
    }

    private func arrayAtPath(path: [JSONPathType], detectNull: Swift.Bool = false) throws -> [JSON] {
        let json = try descendantAtPath(path, detectNull: detectNull)
        guard case let .Array(array) = json else {
            throw Error.ValueNotConvertible(type: Swift.Array<JSON>.self)
        }
        return array
    }

    private func dictionaryAtPath(path: [JSONPathType], detectNull: Swift.Bool = false) throws -> [Swift.String: JSON] {
        let json = try descendantAtPath(path, detectNull: detectNull)
        guard case let .Dictionary(dictionary) = json else {
            throw Error.ValueNotConvertible(type: Swift.Dictionary<Swift.String, JSON>.self)
        }
        return dictionary
    }

    /// Attempts to decode into the returning type from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter type: If the context this method is called from does not
    ///   make the return type clear, pass a type implementing `JSONDecodable`
    ///   to disambiguate the type to decode with.
    /// - returns: An initialized member from the inner JSON.
    /// - throws: One of the following errors contained in `JSON.Error`:
    ///   * `KeyNotFound`: A given `String` key does not exist inside a
    ///     descendant `JSON` dictionary.
    ///   * `IndexOutOfBounds`: A given `Int` index is outside the bounds of a
    ///     descendant `JSON` array.
    ///   * `UnexpectedSubscript`: A given subscript cannot be used with the
    ///     corresponding `JSON` value.
    ///   * `TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Decoded`.
    public func decode<Decoded: JSONDecodable>(path: JSONPathType..., type: Decoded.Type = Decoded.self) throws -> Decoded {
        return try decodedAtPath(path)
    }

    /// Retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A floating-point `Double`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func double(path: JSONPathType...) throws -> Swift.Double {
        return try decodedAtPath(path)
    }

    /// Retrieves an `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A numeric `Int`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func int(path: JSONPathType...) throws -> Swift.Int {
        return try decodedAtPath(path)
    }

    /// Retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A textual `String`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func string(path: JSONPathType...) throws -> Swift.String {
        return try decodedAtPath(path)
    }

    /// Retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A truthy `Bool`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func bool(path: JSONPathType...) throws -> Swift.Bool {
        return try decodedAtPath(path)
    }

    // MARK: Complex member unpacking

    /// Retrieves a `[JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Array` of `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func array(path: JSONPathType...) throws -> [JSON] {
        return try arrayAtPath(path)
    }

    /// Retrieves a `[String: JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func dictionary(path: JSONPathType...) throws -> [Swift.String: JSON] {
        return try dictionaryAtPath(path)
    }

    // MARK: Simple optional unpacking

    private func catchOptional<Value>(path: [JSONPathType], ifNotFound: Swift.Bool, ifNull: Swift.Bool, @noescape getter: ([JSONPathType], detectNull: Swift.Bool) throws -> Value) throws -> Value? {
        do {
            return try getter(path, detectNull: true)
        } catch Error.KeyNotFound where ifNotFound {
            return nil
        } catch Error.IndexOutOfBounds where ifNotFound {
            return nil
        } catch SubscriptError.SubscriptIntoNull where ifNull {
            return nil
        } catch SubscriptError.SubscriptIntoNull(let type) where ifNotFound && type == Swift.String.self {
            return nil
        } catch SubscriptError.SubscriptIntoNull(let type) {
            throw Error.UnexpectedSubscript(type: type)
        } catch Error.UnexpectedSubscript(let type) where ifNotFound && type == Swift.String.self {
            return nil
        }
    }

    private func decodedAtPath<Decoded: JSONDecodable>(path: [JSONPathType], ifNotFound: Swift.Bool, ifNull: Swift.Bool) throws -> Decoded? {
        return try catchOptional(path, ifNotFound: ifNotFound, ifNull: ifNull, getter: decodedAtPath)
    }

    private func arrayAtPath(path: [JSONPathType], ifNotFound: Swift.Bool, ifNull: Swift.Bool) throws -> [JSON]? {
        return try catchOptional(path, ifNotFound: ifNotFound, ifNull: ifNull, getter: arrayAtPath)
    }

    private func dictionaryAtPath(path: [JSONPathType], ifNotFound: Swift.Bool, ifNull: Swift.Bool) throws -> [Swift.String: JSON]? {
        return try catchOptional(path, ifNotFound: ifNotFound, ifNull: ifNull, getter: dictionaryAtPath)
    }

    //return try catchOptional(path, ifNotFound: ifNotFound, ifNull: false, getter: arrayAtPath)

    /// Optionally decodes into the returning type from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - parameter type: If the context this method is called from does not
    ///   make the return type clear, pass a type implementing `JSONDecodable`
    ///   to disambiguate the type to decode with.
    /// - returns: A decoded value from the inner JSON if found, or `nil`.
    /// - throws: One of the following errors contained in `JSON.Error`:
    ///   * `UnexpectedSubscript`: A `path` item cannot be used with the
    ///     corresponding `JSON` value.
    ///   * If `ifNotFound` is `false`, `KeyNotFound`: A key `path` does not
    ///     exist inside a descendant `JSON` dictionary.
    ///   * If `ifNotFound` is `false`, `IndexOutOfBounds`: An index `path` is
    ///     outside the bounds of a descendant `JSON` array.
    ///   * `TypeNotConvertible`: The target value's type inside of the `JSON`
    ///     instance does not match the decoded value.
    ///   * Any error that arises from decoding the value.
    public func decode<Decoded: JSONDecodable>(path: JSONPathType..., ifNotFound: Swift.Bool, type: Decoded.Type = Decoded.self) throws -> Decoded? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A `Double` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func double(path: JSONPathType..., ifNotFound: Swift.Bool) throws -> Swift.Double? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A numeric `Int` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func int(path: JSONPathType..., ifNotFound: Swift.Bool) throws -> Swift.Int? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A text `String` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func string(path: JSONPathType..., ifNotFound: Swift.Bool) throws -> Swift.String? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A truthy `Bool` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func bool(path: JSONPathType..., ifNotFound: Swift.Bool) throws -> Swift.Bool? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally decodes into the returning type from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///   as `nil`.
    /// - parameter type: If the context this method is called from does not
    ///   make the return type clear, pass a type implementing `JSONDecodable`
    ///   to disambiguate the type to decode with.
    /// - returns: A decoded value from the inner JSON if found, or `nil`.
    /// - throws: One of the following errors contained in `JSON.Error`:
    ///   * `KeyNotFound`: A key `path` does not exist inside a descendant
    ///     `JSON` dictionary.
    ///   * `IndexOutOfBounds`: An index `path` is outside the bounds of a
    ///     descendant `JSON` array.
    ///   * `UnexpectedSubscript`: A `path` item cannot be used with the
    ///     corresponding `JSON` value.
    ///   * `TypeNotConvertible`: The target value's type inside of the `JSON`
    ///     instance does not match the decoded value.
    ///   * Any error that arises from decoding the value.
    public func decode<Decoded: JSONDecodable>(path: JSONPathType..., ifNull: Swift.Bool, type: Decoded.Type = Decoded.self) throws -> Decoded? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A `Double` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func double(path: JSONPathType..., ifNull: Swift.Bool) throws -> Swift.Double? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A numeric `Int` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func int(path: JSONPathType..., ifNull: Swift.Bool) throws -> Swift.Int? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A text `String` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func string(path: JSONPathType..., ifNull: Swift.Bool) throws -> Swift.String? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A truthy `Bool` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func bool(path: JSONPathType..., ifNull: Swift.Bool) throws -> Swift.Bool? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    // MARK: Complex optional unpacking

    /// Optionally retrieves a `[JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - returns: An `Array` of `JSON` elements if a value could be found,
    ///   otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func array(path: JSONPathType..., ifNotFound: Swift.Bool) throws -> [JSON]? {
        return try arrayAtPath(path, ifNotFound: ifNotFound, ifNull: false)
    }

    /// Optionally retrieves a `[String: JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - returns: A `Dictionary` of `String` mapping to `JSON` elements if a
    ///   value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func dictionary(path: JSONPathType..., ifNotFound: Swift.Bool) throws -> [Swift.String: JSON]? {
        return try dictionaryAtPath(path, ifNotFound: ifNotFound, ifNull: false)
    }

    /// Optionally retrieves a `[JSON]` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///   as `nil`.
    /// - returns: An `Array` of `JSON` elements if a value could be found,
    ///   otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func array(path: JSONPathType..., ifNull: Swift.Bool) throws -> [JSON]? {
        return try arrayAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `[String: JSON]` from a path into the recieving
    /// structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///   as `nil`.
    /// - returns: A `Dictionary` of `String` mapping to `JSON` elements if a
    ///   value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func dictionary(path: JSONPathType..., ifNull: Swift.Bool) throws -> [Swift.String: JSON]? {
        return try dictionaryAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    // MARK: Member unpacking with fallback

    private func decodedAtPath<Decoded: JSONDecodable>(path: [JSONPathType], @autoclosure or fallback: () -> Decoded) throws -> Decoded {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false) ?? fallback()
    }

    private func arrayAtPath(path: [JSONPathType], @autoclosure or fallback: () -> [JSON]) throws -> [JSON] {
        return try arrayAtPath(path, ifNotFound: true, ifNull: false) ?? fallback()
    }

    private func dictionaryAtPath(path: [JSONPathType], @autoclosure or fallback: () -> [Swift.String: JSON]) throws -> [Swift.String: JSON] {
        return try dictionaryAtPath(path, ifNotFound: true, ifNull: false) ?? fallback()
    }

    /// Attempts to decode into the returning type from a path into
    /// JSON, or returns a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Value to use when one is missing at the subscript.
    /// - returns: An initialized member from the inner JSON.
    /// - throws: One of the following errors contained in `JSON.Error`:
    ///   * `UnexpectedSubscript`: A given subscript cannot be used with the
    ///     corresponding `JSON` value.
    ///   * `TypeNotConvertible`: The target value's type inside of
    ///     the `JSON` instance does not match `Decoded`.
    public func decode<Decoded: JSONDecodable>(path: JSONPathType..., @autoclosure or fallback: () -> Decoded) throws -> Decoded {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves a `Double` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A floating-point `Double`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func double(path: JSONPathType..., @autoclosure or fallback: () -> Swift.Double) throws -> Swift.Double {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves an `Int` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A numeric `Int`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func int(path: JSONPathType..., @autoclosure or fallback: () -> Swift.Int) throws -> Swift.Int {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves a `String` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A textual `String`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func string(path: JSONPathType..., @autoclosure or fallback: () -> Swift.String) throws -> Swift.String {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves a `Bool` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A truthy `Bool`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func bool(path: JSONPathType..., @autoclosure or fallback: () -> Swift.Bool) throws -> Swift.Bool {
        return try decodedAtPath(path, or: fallback)
    }

    // MARK: Complex member unpacking with fallback

    /// Retrieves a `[JSON]` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: An `Array` of `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func array(path: JSONPathType..., @autoclosure or fallback: () -> [JSON]) throws -> [JSON] {
        return try arrayAtPath(path, or: fallback)
    }

    /// Retrieves a `[String: JSON]` from a path into JSON or a fallback if not
    /// found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Value to use when one is missing at the subscript
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func dictionary(path: JSONPathType..., @autoclosure or fallback: () -> [Swift.String: JSON]) throws -> [Swift.String: JSON] {
        return try dictionaryAtPath(path, or: fallback)
    }

}
