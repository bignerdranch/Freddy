//
//  JSONSubscripting.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 8/15/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

extension JSON {

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

    // MARK: Subscripting core

    public enum PathFragment {
        case Key(Swift.String)
        case Index(Swift.Int)
    }

    private enum SubscriptError: ErrorType {
        case SubscriptIntoNull(PathFragment)
    }

    private func valueAtPath<Sequence: SequenceType where Sequence.Generator.Element == PathFragment>(path: Sequence, detectNull: Swift.Bool) throws -> JSON {
        return try path.reduce(self) {
            switch ($0, $1) {
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
            case (.Null, let badFragment) where detectNull:
                throw SubscriptError.SubscriptIntoNull(badFragment)
            case (_, let badFragment):
                throw Error.UnexpectedSubscript(type: badFragment.valueType)
            }
        }
    }

    // MARK: Native subscripting convenience

    public subscript(key: Swift.String) -> JSON? {
        let path = CollectionOfOne(PathFragment.Key(key))
        return try? valueAtPath(path, detectNull: false)
    }

    public subscript(index: Swift.Int) -> JSON? {
        let path = CollectionOfOne(PathFragment.Index(index))
        return try? valueAtPath(path, detectNull: false)
    }

    // MARK: Simple member unpacking

    @transparent private func fetchValueAtPath<Value>(first: PathFragment, _ rest: [PathFragment], @noescape getter: JSON throws -> Value) throws -> Value {
        var path = rest
        path.insert(first, atIndex: path.startIndex)
        let json = try valueAtPath(path, detectNull: false)
        return try getter(json)
    }

    @transparent private func decodedAtPath<Decoded: JSONDecodable>(first: PathFragment, _ rest: [PathFragment]) throws -> Decoded {
        return try fetchValueAtPath(first, rest, getter: Decoded.init)
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
        return try decodedAtPath(first, rest)
    }

    /// Retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A floating-point `Double`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func double(first: PathFragment, _ rest: PathFragment...) throws -> Swift.Double {
        return try decodedAtPath(first, rest)
    }

    /// Retrieves an `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A numeric `Int`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func int(first: PathFragment, _ rest: PathFragment...) throws -> Swift.Int {
        return try decodedAtPath(first, rest)
    }

    /// Retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A textual `String`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func string(first: PathFragment, _ rest: PathFragment...) throws -> Swift.String {
        return try decodedAtPath(first, rest)
    }

    /// Retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: A truthy `Bool`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func bool(first: PathFragment, _ rest: PathFragment...) throws -> Swift.Bool {
        return try decodedAtPath(first, rest)
    }

    // MARK: Complex member unpacking

    /// Retrieves a `[JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Array` of `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func array(first: PathFragment, _ rest: PathFragment...) throws -> [JSON] {
        return try fetchValueAtPath(first, rest) { try $0.array() }
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
        let array = try fetchValueAtPath(first, rest) { try $0.array() }
        return try array.map(Decoded.init)
    }

    /// Retrieves a `[String: JSON]` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:type:)`.
    /// - seealso: `JSON.decode(_:type:)`
    public func dictionary(first: PathFragment, _ rest: PathFragment...) throws -> [Swift.String: JSON] {
        return try fetchValueAtPath(first, rest) { try $0.dictionary() }
    }

    // MARK: Simple optional unpacking

    private func optionalAtPath<Value>(path: [PathFragment], ifNotFound: Swift.Bool, ifNull: Swift.Bool, @noescape getter: JSON throws -> Value) throws -> Value? {
        var json: JSON?
        do {
            json = try valueAtPath(path, detectNull: true)
            return try getter(unsafeUnwrap(json))
        } catch Error.IndexOutOfBounds where ifNotFound {
            return nil
        } catch Error.KeyNotFound where ifNotFound {
            return nil
        } catch Error.UnexpectedSubscript(let type) where ifNotFound && type == Swift.String.self {
            return nil
        } catch Error.ValueNotConvertible where ifNull && json == .Null {
            return nil
        }  catch SubscriptError.SubscriptIntoNull where ifNull {
            return nil
        } catch SubscriptError.SubscriptIntoNull(.Key) where ifNotFound {
            return nil
        } catch SubscriptError.SubscriptIntoNull(let fragment) {
            throw Error.UnexpectedSubscript(type: fragment.valueType)
        }
    }

    @transparent private func decodedAtPath<Decoded: JSONDecodable>(path: [PathFragment], ifNotFound: Swift.Bool, ifNull: Swift.Bool) throws -> Decoded? {
        return try optionalAtPath(path, ifNotFound: ifNotFound, ifNull: ifNull, getter: Decoded.init)
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
        return try decodedAtPath(path, ifNotFound: ifNotFound, ifNull: false)
    }

    /// Optionally retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A `Double` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func double(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.Double? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A numeric `Int` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func int(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.Int? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A text `String` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func string(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.String? {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false)
    }

    /// Optionally retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNotFound: If `true`, missing key or index errors are
    ///             treated as `nil`.
    /// - returns: A truthy `Bool` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNotFound:type:)`.
    /// - seealso: `JSON.decode(_:ifNotFound:type:)`
    public func bool(path: PathFragment..., ifNotFound: Swift.Bool) throws -> Swift.Bool? {
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
    public func decode<Decoded: JSONDecodable>(path: PathFragment..., ifNull: Swift.Bool, type: Decoded.Type = Decoded.self) throws -> Decoded? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `Double` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A `Double` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func double(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.Double? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `Int` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A numeric `Int` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func int(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.Int? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `String` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A text `String` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func string(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.String? {
        return try decodedAtPath(path, ifNotFound: false, ifNull: ifNull)
    }

    /// Optionally retrieves a `Bool` from a path into JSON.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter ifNull: If `true`, target values matching `Null` are treated
    ///             as `nil`.
    /// - returns: A truthy `Bool` if a value could be found, otherwise `nil`.
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:ifNull:type:)`.
    /// - seealso: `JSON.decode(_:ifNull:type:)`
    public func bool(path: PathFragment..., ifNull: Swift.Bool) throws -> Swift.Bool? {
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
    public func array(path: PathFragment..., ifNotFound: Swift.Bool) throws -> [JSON]? {
        return try optionalAtPath(path, ifNotFound: ifNotFound, ifNull: false) { try $0.array() }
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
        let array = try optionalAtPath(path, ifNotFound: ifNotFound, ifNull: false) { try $0.array() }
        return try array?.map(Decoded.init)
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
        return try optionalAtPath(path, ifNotFound: ifNotFound, ifNull: false) { try $0.dictionary() }
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
        return try optionalAtPath(path, ifNotFound: false, ifNull: ifNull) { try $0.array() }
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
        let array = try optionalAtPath(path, ifNotFound: false, ifNull: ifNull) { try $0.array() }
        return try array?.map(Decoded.init)
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
        return try optionalAtPath(path, ifNotFound: false, ifNull: ifNull) { try $0.dictionary() }
    }

    // MARK: Member unpacking with fallback

    @transparent private func decodedAtPath<Decoded: JSONDecodable>(path: [PathFragment], @noescape or fallback: () -> Decoded) throws -> Decoded {
        return try decodedAtPath(path, ifNotFound: true, ifNull: false) ?? fallback()
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
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves a `Double` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A floating-point `Double`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func double(path: PathFragment..., @autoclosure or fallback: () -> Swift.Double) throws -> Swift.Double {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves an `Int` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A numeric `Int`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func int(path: PathFragment..., @autoclosure or fallback: () -> Swift.Int) throws -> Swift.Int {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves a `String` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A textual `String`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func string(path: PathFragment..., @autoclosure or fallback: () -> Swift.String) throws -> Swift.String {
        return try decodedAtPath(path, or: fallback)
    }

    /// Retrieves a `Bool` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: A truthy `Bool`
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func bool(path: PathFragment..., @autoclosure or fallback: () -> Swift.Bool) throws -> Swift.Bool {
        return try decodedAtPath(path, or: fallback)
    }

    // MARK: Complex member unpacking with fallback

    /// Retrieves a `[JSON]` from a path into JSON or a fallback if not found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Array to use when one is missing at the subscript.
    /// - returns: An `Array` of `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func array(path: PathFragment..., @autoclosure or fallback: () -> [JSON]) throws -> [JSON] {
        let array = try optionalAtPath(path, ifNotFound: true, ifNull: false) { try $0.array() }
        return array ?? fallback()
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
        let array = try optionalAtPath(path, ifNotFound: true, ifNull: false) { try $0.array() }
        return try array?.map(Decoded.init) ?? fallback()
    }

    /// Retrieves a `[String: JSON]` from a path into JSON or a fallback if not
    /// found.
    /// - parameter path: 0 or more `String` or `Int` that subscript the `JSON`
    /// - parameter fallback: Value to use when one is missing at the subscript
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: One of the `JSON.Error` cases thrown by `decode(_:or:)`.
    /// - seealso: `JSON.decode(_:or:)`
    public func dictionary(path: PathFragment..., @autoclosure or fallback: () -> [Swift.String: JSON]) throws -> [Swift.String: JSON] {
        let dictionary = try optionalAtPath(path, ifNotFound: true, ifNull: false) { try $0.dictionary() }
        return dictionary ?? fallback()
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

    private var valueType: Any.Type {
        switch self {
        case .Key: return Swift.String
        case .Index: return Swift.Int
        }
    }

}
