//
//  JSONLiteralConvertible.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/11/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

// MARK: - ArrayLiteralConvertible

extension JSON: ArrayLiteralConvertible {
    
    public init<Collection: CollectionType where Collection.Generator.Element == JSON>(_ collection: Collection) {
        self = .Array(Swift.Array(collection))
    }

    public init(arrayLiteral elements: JSON...) {
        self.init(elements)
    }
    
}

// MARK: - DictionaryLiteralConvertible

extension JSON: DictionaryLiteralConvertible {
    
    public init<Dictionary: SequenceType where Dictionary.Generator.Element == (Swift.String, JSON)>(_ pairs: Dictionary) {
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: underestimateCount(pairs))
        for (key, value) in pairs {
            dictionary[key] = value
        }
        self = .Dictionary(dictionary)
    }
    
    public init(dictionaryLiteral pairs: (Swift.String, JSON)...) {
        self.init(pairs)
    }

}

// MARK: - FloatLiteralConvertible

extension JSON: FloatLiteralConvertible {
    
    public init(_ value: Swift.Double) {
        self = .Double(value)
    }
    
    public init(floatLiteral value: Swift.Double) {
        self.init(value)
    }

}

// MARK: - IntegerLiteralConvertible

extension JSON: IntegerLiteralConvertible {
    
    public init(_ value: Swift.Int) {
        self = .Int(value)
    }
    
    public init(integerLiteral value: Swift.Int) {
        self.init(value)
    }

}

// MARK: - StringLiteralConvertible

extension JSON: StringLiteralConvertible {
    
    public init(_ text: Swift.String) {
        self = .String(text)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
    
}

// MARK: - BooleanLiteralConvertible

extension JSON: BooleanLiteralConvertible {

    public init(_ value: Swift.Bool) {
        self = .Bool(value)
    }

    public init(booleanLiteral value: Swift.Bool) {
        self.init(value)
    }

}

// MARK: - NilLiteralConvertible

extension JSON: NilLiteralConvertible {

    public init(nilLiteral: ()) {
        self = .Null
    }

}
