//
//  JSONDecodable.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

/// A protocol to provide functionality for creating a model object with a `JSON`
/// value.
public protocol JSONDecodable {
    
    /// Creates an instance of the model with a `JSON` instance.
    /// - parameter json: An instance of a `JSON` value from which to
    ///             construct an instance of the implementing type.
    /// - throws: Any `JSON.Error` for errors derived from inspecting the
    ///           `JSON` value, or any other error involved in decoding.
    init(json: JSON) throws
    
}

extension Double: JSONDecodable {
    
    /// An initializer to create an instance of `Double` from a `JSON` value.
    /// - parameter json: An instance of `JSON`.
    /// - throws: The initializer will throw an instance of `JSON.Error` if 
    /// an instance of `Double` cannot be created from the `JSON` value that was 
    /// passed to this initializer.
    public init(json: JSON) throws {
        switch json {
        case let .Double(double):
            self.init(double)
        case let .Int(int):
            self.init(int)
        default:
            throw JSON.Error.ValueNotConvertible(type: Swift.Double)
        }
    }
    
}

extension IntMax: JSONDecodable {
    
    /// An initializer to create an instance of `Int` from a `JSON` value.
    /// - parameter json: An instance of `JSON`.
    /// - throws: The initializer will throw an instance of `JSON.Error` if
    /// an instance of `Int` cannot be created from the `JSON` value that was
    /// passed to this initializer.
    public init(json: JSON) throws {
        switch json {
        case let .Double(double):
            self.init(double)
        case let .Int(int):
            self.init(int)
        default:
            throw JSON.Error.ValueNotConvertible(type: Swift.IntMax)
        }
    }
    
}

extension String: JSONDecodable {
    
    /// An initializer to create an instance of `String` from a `JSON` value.
    /// - parameter json: An instance of `JSON`.
    /// - throws: The initializer will throw an instance of `JSON.Error` if
    /// an instance of `String` cannot be created from the `JSON` value that was
    /// passed to this initializer.
    public init(json: JSON) throws {
        guard case let .String(string) = json else {
            throw JSON.Error.ValueNotConvertible(type: Swift.String)
        }
        self.init(string)
    }
    
}

extension Bool: JSONDecodable {
    
    /// An initializer to create an instance of `Bool` from a `JSON` value.
    /// - parameter json: An instance of `JSON`.
    /// - throws: The initializer will throw an instance of `JSON.Error` if
    /// an instance of `Bool` cannot be created from the `JSON` value that was
    /// passed to this initializer.
    public init(json: JSON) throws {
        guard case let .Bool(bool) = json else {
            throw JSON.Error.ValueNotConvertible(type: Swift.Bool)
        }
        self.init(bool)
    }
    
}

extension JSON {
    
    /// Attempts to decode into the returning type.
    /// - parameter type: If the context this method is called from does not
    ///   make the return type clear, pass a type implementing `JSONDecodable`
    ///   to disambiguate the type to decode with.
    /// - returns: An initialized member from the JSON.
    /// - throws: Any error that arises while initializing the `JSONDecodable`.
    public func decode<Decoded: JSONDecodable>(type: Decoded.Type = Decoded.self) throws -> Decoded {
        return try Decoded(json: self)
    }
    
    /// Retrieves a `Double` from the JSON.
    /// - returns: A floating-point `Double`
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`.
    /// - seealso: `JSON.decode(type:)`
    public func double() throws -> Swift.Double {
        return try decode()
    }
    
    /// Retrieves an `Int` from the JSON.
    /// - returns: A numeric `Int`
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`.
    /// - seealso: `JSON.decode(type:)`
    public func int() throws -> Swift.IntMax {
        return try decode()
    }
    
    /// Retrieves a `String` from the JSON.
    /// - returns: A textual `String`
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`.
    /// - seealso: `JSON.decode(type:)`
    public func string() throws -> Swift.String {
        return try decode()
    }
    
    /// Retrieves a `Bool` from the JSON.
    /// - returns: A truthy `Bool`
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`.
    /// - seealso: `JSON.decode(type:)`
    public func bool() throws -> Swift.Bool {
        return try decode()
    }
    
    /// Retrieves a `[JSON]` from the JSON.
    /// - returns: An `Array` of `JSON` elements
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`.
    /// - seealso: `JSON.decode(type:)`
    public func array() throws -> [JSON] {
        guard case let .Array(array) = self else {
            throw Error.ValueNotConvertible(type: Swift.Array<JSON>)
        }
        return array
    }
    
    /// Retrieves a `[String: JSON]` from the JSON.
    /// - returns: An `Dictionary` of `String` mapping to `JSON` elements
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`.
    /// - seealso: `JSON.decode(type:)`
    public func dictionary() throws -> [Swift.String: JSON] {
        guard case let .Dictionary(dictionary) = self else {
            throw Error.ValueNotConvertible(type: Swift.Dictionary<Swift.String, JSON>)
        }
        return dictionary
    }
    
    /// Attempts to decode many values from a descendant JSON array at a path
    /// into JSON.
    /// - parameter type: If the context this method is called from does not
    ///   make the return type clear, pass a type implementing `JSONDecodable`
    ///   to disambiguate the type to decode with.
    /// - returns: An `Array` of decoded elements
    /// - throws: Any of the `JSON.Error` cases thrown by `decode(type:)`, as
    ///   well as any error that arises from decoding the contained values.
    /// - seealso: `JSON.decode(type:)`
    public func arrayOf<Decoded: JSONDecodable>(type type: Decoded.Type = Decoded.self) throws -> [Decoded] {
        return try array().map { try $0.decode() }
    }
    
}
