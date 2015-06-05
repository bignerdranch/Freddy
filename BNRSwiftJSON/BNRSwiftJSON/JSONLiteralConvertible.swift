//
//  JSONLiteralConvertible.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/11/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

// MARK: - ArrayLiteralConvertible

extension JSON: ArrayLiteralConvertible {
    
    public init(arrayLiteral elements: JSON...) {
        self = .Array(elements)
    }
    
}

// MARK: - DictionaryLiteralConvertible

extension JSON: DictionaryLiteralConvertible {
    
    public init(dictionaryLiteral pairs: (Swift.String, JSON)...) {
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: pairs.count)
        for (key, value) in pairs {
            dictionary[key] = value
        }
        self = .Dictionary(dictionary)
    }
    
}

// MARK: - FloatLiteralConvertible

extension JSON: FloatLiteralConvertible {
    
    public init(floatLiteral value: FloatLiteralType) {
        self = .Double(value)
    }
    
}

// MARK: - IntegerLiteralConvertible

extension JSON: IntegerLiteralConvertible {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self = .Int(value)
    }
    
}

// MARK: - StringLiteralConvertible

extension JSON: StringLiteralConvertible {
    
    public init(stringLiteral value: StringLiteralType) {
        self = .String(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self = .String(value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self = .String(value)
    }
    
}

// MARK: - BooleanLiteralConvertible

extension JSON: BooleanLiteralConvertible {
    public init(booleanLiteral value: Swift.Bool) {
        self = .Bool(value)
    }
}

// MARK: - NilLiteralConvertible

extension JSON: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self = .Null
    }
}
