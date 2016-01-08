//
//  JSONSubscripting.swift
//  Freddy
//
//  Created by Zachary Waldowski on 8/15/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

// Subscript implementation notes:
//
// Interior varargs lists in Swift 2 may be called with 1 or many values.
// Trailing varargs lists may be called with 0, 1, or many values.
//
// This works as intended for the extended fallback subscripts:
//  json.int(param: "qux")                      // error
//  json.int("foo", "bar", "baz", param: "qux") // works
//
// For the trailing varargs, there's an inherent ambiguity for the
// JSON.PathFragment literals that Swift refuses to solve. So we must
// imitate the interior varargs style, and provide overloads for empty args:
//  func foo(first: PathFragment, _ rest: PathFragment...)
//  func foo()

// MARK: PathFragment

extension JSON {

    public enum PathFragment {
        case Key(Swift.String)
        case Index(Swift.Int)
    }

}

extension JSON.PathFragment: IntegerLiteralConvertible, StringLiteralConvertible {

    public init(integerLiteral value: Int) {
        self = .Index(value)
    }

    public init(unicodeScalarLiteral value: String) {
        self = .Key(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .Key(value)
    }

    public init(stringLiteral value: String) {
        self = .Key(value)
    }
    
}

// MARK: - Subscripting core

extension JSON {

    private enum SubscriptError: ErrorType {
        case SubscriptIntoNull(PathFragment)
    }

    private func valueForPathFragment(fragment: PathFragment, detectNull: Swift.Bool) throws -> JSON {
        switch (self, fragment) {
        case let (.Dictionary(dict), .Key(key)):
            guard let next = dict[key] else {
                throw Error.KeyNotFound(key: key)
            }
            return next
        case let (.Array(array), .Index(index)):
            guard array.startIndex.advancedBy(index, limit: array.endIndex) != array.endIndex else {
                throw Error.IndexOutOfBounds(index: index)
            }
            return array[index]
        case let (.Null, badFragment) where detectNull:
            throw SubscriptError.SubscriptIntoNull(badFragment)
        case (_, .Key):
            throw Error.UnexpectedSubscript(type: Swift.String.self)
        case (_, .Index):
            throw Error.UnexpectedSubscript(type: Swift.Int.self)
        }
    }

    private func valueAtPath(path: [PathFragment], detectNull: Swift.Bool) throws -> JSON {
        var result = self
        for fragment in path {
            result = try result.valueForPathFragment(fragment, detectNull: detectNull)
        }
        return result
    }

}

// MARK: - Subscripting operator

extension JSON {

    public subscript(key: Swift.String) -> JSON? {
        return try? valueForPathFragment(.Key(key), detectNull: false)
    }

    public subscript(index: Swift.Int) -> JSON? {
        return try? valueForPathFragment(.Index(index), detectNull: false)
    }

}

// MARK: - Simple member unpacking

extension JSON {

    private func mapAtPath<Value>(first: PathFragment, _ rest: [PathFragment], @noescape transform: JSON throws -> Value) throws -> Value {
        var result = try valueForPathFragment(first, detectNull: false)
        for fragment in rest {
            result = try result.valueForPathFragment(fragment, detectNull: false)
        }
        return try transform(result)
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
    public func decode<Decoded: JSONDecodable>(first: PathFragment, _ rest: PathFragment..., type: Decoded.Type = Decoded.self) throws -> Decoded {
        return try mapAtPath(first, rest) { try $0.decode() }
    }

    /// Retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A floating-point `Double`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func double(first: PathFragment, _ rest: PathFragment...) throws -> Swift.Double {
        return try mapAtPath(first, rest) { try $0.double() }
    }

    /// Retrieves an `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A numeric `Int`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func int(first: PathFragment, _ rest: PathFragment...) throws -> Swift.Int {
        return try mapAtPath(first, rest) { try $0.int() }
    }

    /// Retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A textual `String`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func string(first: PathFragment, _ rest: PathFragment...) throws -> Swift.String {
        return try mapAtPath(first, rest) { try $0.string() }
    }

    /// Retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A truthy `Bool`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func bool(first: PathFragment, _ rest: PathFragment...) throws -> Swift.Bool {
        return try mapAtPath(first, rest) { try $0.bool() }
    }

    /// Retrieves a `[JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Array` of `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func array(first: PathFragment, _ rest: PathFragment...) throws -> [JSON] {
        return try mapAtPath(first, rest) { try $0.array() }
    }

    /// Attempts to decodes many values from a desendant JSON array at a path
    /// into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter type: If the context this method is called from does not
    ///   make the return type clear, pass a type implementing `JSONDecodable`
    ///   to disambiguate the type to decode with.
    /// - returns: An `Array` of decoded elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`, or
    ///   any error that arises from decoding the contained values.
    /// - seealso: `JSON.decode(_:type:)`
    public func arrayOf<Decoded: JSONDecodable>(first: PathFragment, _ rest: PathFragment..., type: Decoded.Type = Decoded.self) throws -> [Decoded] {
        return try mapAtPath(first, rest) { try $0.arrayOf() }
    }

    /// Retrieves a `[String: JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func dictionary(first: PathFragment, _ rest: PathFragment...) throws -> [Swift.String: JSON] {
        return try mapAtPath(first, rest) { try $0.dictionary() }
    }

}

// MARK: - Missing-to-Optional unpacking

extension JSON {

    private func mapOptionalAtPath<Value>(path: [PathFragment], ifNotFound: Swift.Bool, @noescape transform: JSON throws -> Value) throws -> Value? {
        do {
            return try transform(valueAtPath(path, detectNull: true))
        } catch Error.IndexOutOfBounds where ifNotFound {
            return nil
        } catch Error.KeyNotFound where ifNotFound {
            return nil
        } catch Error.UnexpectedSubscript(let type) where ifNotFound && type == Swift.String.self {
            return nil
        } catch SubscriptError.SubscriptIntoNull(.Key) where ifNotFound {
            return nil
        } catch SubscriptError.SubscriptIntoNull(.Key) {
            throw Error.UnexpectedSubscript(type: Swift.String.self)
        } catch SubscriptError.SubscriptIntoNull(.Index) {
            throw Error.UnexpectedSubscript(type: Swift.Int.self)
        }
    }

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
    public func decode<Decoded: JSONDecodable>(path: PathFragment..., ifNotFound: Swift.Bool, type: Decoded.Type = Decoded.self) throws -> Decoded? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.decode() }
    }

    /// Optionally retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A `Double` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func double(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.Double? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.double() }
    }

    /// Optionally retrieves a `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A numeric `Int` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func int(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.Int? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.int() }
    }

    /// Optionally retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A text `String` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func string(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.String? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.string() }
    }

    /// Optionally retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A truthy `Bool` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func bool(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.Bool? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.bool() }
    }

    /// Optionally retrieves a `[JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - returns: An `Array` of `JSON` elements if a value could be found,
    ///   otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func array(path: PathFragment..., ifNotFound: Swift.Bool) throws -> [JSON]? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.array() }
    }

    /// Optionally decodes many values from a descendant array at a path into
    /// JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - returns: An `Array` of decoded elements if found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`,
    ///   or any error that arises from decoding the contained values.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func arrayOf<Decoded: JSONDecodable>(path: PathFragment..., ifNotFound: Swift.Bool) throws -> [Decoded]? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.arrayOf() }
    }

    /// Optionally retrieves a `[String: JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - returns: A `Dictionary` of `String` mapping to `JSON` elements if a
    ///   value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func dictionary(path: PathFragment..., ifNotFound: Swift.Bool) throws -> [Swift.String: JSON]? {
        return try mapOptionalAtPath(path, ifNotFound: ifNotFound) { try $0.dictionary() }
    }

}

// MARK: - Missing-with-fallback unpacking

extension JSON {

    private func mapOptionalAtPath<Value>(path: [PathFragment], @noescape fallback: () -> Value, @noescape transform: JSON throws -> Value) throws -> Value {
        return try mapOptionalAtPath(path, ifNotFound: true, transform: transform) ?? fallback()
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
    public func decode<Decoded: JSONDecodable>(path: PathFragment..., @autoclosure or fallback: () -> Decoded) throws -> Decoded {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.decode() }
    }

    /// Retrieves a `Double` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A floating-point `Double`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func double(path: PathFragment..., @autoclosure or fallback: () -> Swift.Double) throws -> Swift.Double {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.double() }
    }

    /// Retrieves an `Int` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A numeric `Int`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func int(path: PathFragment..., @autoclosure or fallback: () -> Swift.Int) throws -> Swift.Int {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.int() }
    }

    /// Retrieves a `String` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A textual `String`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func string(path: PathFragment..., @autoclosure or fallback: () -> Swift.String) throws -> Swift.String {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.string() }
    }

    /// Retrieves a `Bool` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A truthy `Bool`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func bool(path: PathFragment..., @autoclosure or fallback: () -> Swift.Bool) throws -> Swift.Bool {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.bool() }
    }

    /// Retrieves a `[JSON]` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: An `Array` of `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func array(path: PathFragment..., @autoclosure or fallback: () -> [JSON]) throws -> [JSON] {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.array() }
    }

    /// Attempts to decodes many values from a desendant JSON array at a path
    /// into the recieving structure, returning a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: An `Array` of decoded elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`, or
    ///   any error that arises from decoding the contained values.
    /// - seealso: `JSON.decode(_:or:)`
    public func arrayOf<Decoded: JSONDecodable>(path: PathFragment..., @autoclosure or fallback: () -> [Decoded]) throws -> [Decoded] {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.arrayOf() }
    }

    /// Retrieves a `[String: JSON]` from a path into JSON or a fallback if not
    /// found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Value to use when one is missing at the subscript
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func dictionary(path: PathFragment..., @autoclosure or fallback: () -> [Swift.String: JSON]) throws -> [Swift.String: JSON] {
        return try mapOptionalAtPath(path, fallback: fallback) { try $0.dictionary() }
    }

}

// MARK: - Null-to-Optional unpacking

extension JSON {

    private func mapOptionalAtPath<Value>(path: [PathFragment], ifNull: Swift.Bool, @noescape transform: JSON throws -> Value) throws -> Value? {
        var json: JSON?
        do {
            json = try valueAtPath(path, detectNull: ifNull)
            return try json.map(transform)
        } catch SubscriptError.SubscriptIntoNull {
            return nil
        } catch Error.ValueNotConvertible where ifNull && json == .Null {
            return nil
        }
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
    public func decode<Decoded: JSONDecodable>(path: PathFragment..., ifNull: Swift.Bool, type: Decoded.Type = Decoded.self) throws -> Decoded? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.decode() }
    }

    /// Optionally retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A `Double` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func double(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.Double? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.double() }
    }

    /// Optionally retrieves a `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A numeric `Int` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func int(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.Int? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.int() }
    }

    /// Optionally retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A text `String` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func string(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.String? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.string() }
    }

    /// Optionally retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A truthy `Bool` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func bool(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.Bool? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.bool() }
    }

    /// Optionally retrieves a `[JSON]` from a path into the recieving structure.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///   as `nil`.
    /// - returns: An `Array` of `JSON` elements if a value could be found,
    ///   otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func array(path: PathFragment..., ifNull: Swift.Bool) throws -> [JSON]? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.array() }
    }

    /// Optionally decodes many values from a descendant array at a path into
    /// JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///   treated as `nil`.
    /// - returns: An `Array` of decoded elements if found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`,
    ///   or any error that arises from decoding the contained values.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func arrayOf<Decoded: JSONDecodable>(path: PathFragment..., ifNull: Swift.Bool) throws -> [Decoded]? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.arrayOf() }
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
    public func dictionary(path: PathFragment..., ifNull: Swift.Bool) throws -> [Swift.String: JSON]? {
        return try mapOptionalAtPath(path, ifNull: ifNull) { try $0.dictionary() }
    }

}
