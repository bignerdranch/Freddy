//
//  JSONLiteralConvertible.swift
//  Freddy
//
//  Created by Zachary Waldowski on 5/11/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

// MARK: - ArrayLiteralConvertible

extension JSON: ArrayLiteralConvertible {
    
    public init(arrayLiteral elements: JSON...) {
        self = .Array(elements)
    }
    
}

// MARK: - DictionaryLiteralConvertible

extension JSON: DictionaryLiteralConvertible {
    
    public init<Dictionary: SequenceType where Dictionary.Generator.Element == (Swift.String, JSON)>(_ pairs: Dictionary) {
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: pairs.underestimateCount())
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
    
    public init(floatLiteral value: Swift.Double) {
        self = .Double(value)
    }

}

// MARK: - IntegerLiteralConvertible

extension JSON: IntegerLiteralConvertible {
    
    public init(integerLiteral value: Swift.Int) {
        self.init(value)
    }

}

// MARK: - StringLiteralConvertible

extension JSON: StringLiteralConvertible {

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
