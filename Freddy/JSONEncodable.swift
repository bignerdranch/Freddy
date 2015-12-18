//
//  JSONEncodable.swift
//  Freddy
//
//  Created by Zachary Waldowski on 12/17/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

public protocol CustomJSONEncodable {

    var JSONValue: JSON { get }
    
}

extension JSON: CustomJSONEncodable {

    public var JSONValue: JSON {
        return self
    }
    
}

private func adHocJSONValue<T>(value: T) -> JSON {
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .Struct?, .Class?, .Dictionary?:
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: mirror.children.underestimateCount())
        var mirror: Mirror? = mirror

        while let src = mirror {
            for case let (key?, value) in src.children {
                guard dictionary.indexForKey(key) == nil else { continue }
                dictionary[key] = JSON(value)
            }
            mirror = src.superclassMirror()
        }

        return .Dictionary(dictionary)
    case .Tuple?, .Collection?, .Set?:
        return .Array(mirror.children.lazy.map { JSON($0.1) })
    case .Optional?:
        return mirror.children.first.map { JSON($0.value) } ?? .Null
    case .Enum?, nil:
        return .String(String(value))
    }
}

extension JSON {

    /// Initialize `self` with the serialized representation of `value`.
    ///
    /// * If `T` conforms to `CustomJSONEncodable`, the
    ///   result is `instance`'s `JSONValue`
    /// * Otherwise, an unspecified result is supplied automatically by
    ///   the framework.
    public init<T>(_ value: T) {
        if case let encodableValue as CustomJSONEncodable = value {
            self = encodableValue.JSONValue
        } else {
            self = adHocJSONValue(value)
        }
    }
    
}

// MARK: Stdlib primitives

extension Double: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .Double(self)
    }

}

extension Float: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .Double(Swift.Double(self))
    }
    
}

extension SignedIntegerType {

    public var JSONValue: JSON {
        return .Int(numericCast(self))
    }

}

extension Int: CustomJSONEncodable    {}
extension Int8: CustomJSONEncodable   {}
extension Int16: CustomJSONEncodable  {}
extension Int32: CustomJSONEncodable  {}
extension Int64: CustomJSONEncodable  {}

extension UnsignedIntegerType {

    public var JSONValue: JSON {
        return .Int(numericCast(self))
    }

}

extension UInt: CustomJSONEncodable   {}
extension UInt8: CustomJSONEncodable  {}
extension UInt16: CustomJSONEncodable {}
extension UInt32: CustomJSONEncodable {}
extension UInt64: CustomJSONEncodable {}

extension String: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .String(self)
    }

}

extension Character: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .String(String(self))
    }
    
}

extension String.CharacterView: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .String(String(self))
    }

}

extension String.UnicodeScalarView: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .String(String(self))
    }
    
}

extension BooleanType {

    public var JSONValue: JSON {
        return .Bool(boolValue)
    }

}

extension Bool: CustomJSONEncodable   {}

extension Optional: CustomJSONEncodable {

    public var JSONValue: JSON {
        return map(JSON.init) ?? .Null
    }
    
}

// MARK: Enums

extension RawRepresentable {

    public var JSONValue: JSON {
        return JSON(rawValue)
    }
    
}

// MARK: Stdlib collections compatibility

extension SequenceType {

    public var JSONValue: JSON {
        return .Array(map(JSON.init))
    }

}

extension EmptyCollection: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .Array([])
    }

}

extension AnyBidirectionalCollection: CustomJSONEncodable     {}
extension AnyForwardCollection: CustomJSONEncodable           {}
extension AnyRandomAccessCollection: CustomJSONEncodable      {}
extension AnySequence: CustomJSONEncodable                    {}
extension ArraySlice: CustomJSONEncodable                     {}
extension CollectionOfOne: CustomJSONEncodable                {}
extension ContiguousArray: CustomJSONEncodable                {}
extension DictionaryLiteral: CustomJSONEncodable              {}
extension EnumerateSequence: CustomJSONEncodable              {}
extension FlattenBidirectionalCollection: CustomJSONEncodable {}
extension FlattenCollection: CustomJSONEncodable              {}
extension FlattenSequence: CustomJSONEncodable                {}
extension GeneratorOfOne: CustomJSONEncodable                 {}
extension GeneratorSequence: CustomJSONEncodable              {}
extension IndexingGenerator: CustomJSONEncodable              {}
extension JoinSequence: CustomJSONEncodable                   {}
extension LazyCollection: CustomJSONEncodable                 {}
extension LazyFilterCollection: CustomJSONEncodable           {}
extension LazyFilterSequence: CustomJSONEncodable             {}
extension LazyMapCollection: CustomJSONEncodable              {}
extension LazyMapSequence: CustomJSONEncodable                {}
extension LazySequence: CustomJSONEncodable                   {}
extension MutableSlice: CustomJSONEncodable                   {}
extension PermutationGenerator: CustomJSONEncodable           {}
extension Range: CustomJSONEncodable                          {}
extension RangeGenerator: CustomJSONEncodable                 {}
extension Repeat: CustomJSONEncodable                         {}
extension ReverseCollection: CustomJSONEncodable              {}
extension ReverseRandomAccessCollection: CustomJSONEncodable  {}
extension Slice: CustomJSONEncodable                          {}
extension StrideThrough: CustomJSONEncodable                  {}
extension StrideTo: CustomJSONEncodable                       {}
extension UnsafeBufferPointer: CustomJSONEncodable            {}
extension UnsafeMutableBufferPointer: CustomJSONEncodable     {}
extension Zip2Sequence: CustomJSONEncodable                   {}
