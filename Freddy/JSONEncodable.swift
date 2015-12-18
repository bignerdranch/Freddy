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

// MARK: -

private extension SequenceType {

    func adHocJSONArray() -> JSON {
        return .Array(map(JSON.init))
    }

    func adHocJSONDictionary(fallbackToArray fallbackToArray: Bool = false) -> JSON {
        // A dictionary mirror looks like:
        //  - ("[0]", (someKey, someValue) as Any)
        //  - ("[1]", (otherKey, otherValue) as Any)
        //  - ...
        // Anything that doesn't follow that exact structure is assumed to be an
        // Array-like thing instead.
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: underestimateCount())
        var successfullyParsed2Tuple = false
        func fallback() -> JSON {
            return fallbackToArray ? adHocJSONArray() : .Dictionary([:])
        }

        for maybePair in self {
            let pairMirror = Mirror(reflecting: maybePair)
            guard successfullyParsed2Tuple || pairMirror.displayStyle == .Tuple else { return fallback() }
            let children = pairMirror.children.generate()

            // children[0] => key
            guard let anyKey = children.next()?.value else { return fallback() }

            // children[1] => value
            guard let anyValue = children.next()?.value else { return fallback() }

            // children[2] should not exist
            guard successfullyParsed2Tuple || children.next() == nil else { return fallback() }
            successfullyParsed2Tuple = true

            let key = String(anyKey)
            let value = JSON(anyValue)
            dictionary[key] = value
        }

        return .Dictionary(dictionary)
    }

}

private extension Mirror {

    func adHocJSONArray() -> JSON {
        return children.lazy.map { $0.value }.adHocJSONArray()
    }

    func adHocJSONDictionary(fallbackToArray fallback: Bool = false) -> JSON {
        return children.lazy.map { $0.value }.adHocJSONDictionary(fallbackToArray: fallback)
    }

}

private func adHocJSONValue<T>(value: T) -> JSON {
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .Struct?, .Class?:
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: mirror.children.underestimateCount())
        
        var nextMirror: Mirror? = mirror
        while let mirror = nextMirror {
            for case let (key?, value) in mirror.children {
                guard dictionary.indexForKey(key) == nil else { continue }
                dictionary[key] = JSON(value)
            }
            nextMirror = mirror.superclassMirror()
        }

        return .Dictionary(dictionary)
    case .Tuple?, .Set?:
        return mirror.adHocJSONArray()
    case .Optional?:
        return mirror.children.first.map { JSON($0.value) } ?? .Null
    case .Collection?:
        return mirror.adHocJSONDictionary(fallbackToArray: true)
    case .Dictionary?:
        return mirror.adHocJSONDictionary()
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
        return adHocJSONDictionary(fallbackToArray: true)
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

// MARK: Foundation compatibility

import Foundation

extension NSDictionary: CustomJSONEncodable {

    public var JSONValue: JSON {
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: count)
        enumerateKeysAndObjectsUsingBlock { (key, object, _) in
            dictionary[String(key)] = JSON(object)
        }
        return .Dictionary(dictionary)
    }

}

extension NSNull: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .Null
    }

}

extension NSNumber: CustomJSONEncodable {

    public var JSONValue: JSON {
        if CFGetTypeID(self) == CFBooleanGetTypeID() || CFNumberGetType(self) == .CharType {
            return .Bool(boolValue)
        } else if !CFNumberIsFloatType(self) {
            return .Int(integerValue)
        } else {
            return .Double(doubleValue)
        }
    }
    
}

extension NSString: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .String(self as String)
    }

}

extension NSURL: CustomJSONEncodable {

    public var JSONValue: JSON {
        return .String(absoluteString)
    }

}

extension NSArray: CustomJSONEncodable      {}
extension NSEnumerator: CustomJSONEncodable {}
extension NSOrderedSet: CustomJSONEncodable {}
extension NSSet: CustomJSONEncodable        {}
