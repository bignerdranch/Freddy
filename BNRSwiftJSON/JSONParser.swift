//
//  JSONParser.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 4/18/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

private struct Literal {
    static let BACKSLASH     = UInt8(ascii: "\\")
    static let BACKSPACE     = UInt8(ascii: "\u{0008}")
    static let COLON         = UInt8(ascii: ":")
    static let COMMA         = UInt8(ascii: ",")
    static let DOUBLE_QUOTE  = UInt8(ascii: "\"")
    static let FORMFEED      = UInt8(ascii: "\u{000c}")
    static let LEFT_BRACE    = UInt8(ascii: "{")
    static let LEFT_BRACKET  = UInt8(ascii: "[")
    static let MINUS         = UInt8(ascii: "-")
    static let NEWLINE       = UInt8(ascii: "\n")
    static let PERIOD        = UInt8(ascii: ".")
    static let PLUS          = UInt8(ascii: "+")
    static let RETURN        = UInt8(ascii: "\r")
    static let RIGHT_BRACE   = UInt8(ascii: "}")
    static let RIGHT_BRACKET = UInt8(ascii: "]")
    static let SLASH         = UInt8(ascii: "/")
    static let SPACE         = UInt8(ascii: " ")
    static let TAB           = UInt8(ascii: "\t")

    static let a = UInt8(ascii: "a")
    static let b = UInt8(ascii: "b")
    static let c = UInt8(ascii: "c")
    static let d = UInt8(ascii: "d")
    static let e = UInt8(ascii: "e")
    static let f = UInt8(ascii: "f")
    static let l = UInt8(ascii: "l")
    static let n = UInt8(ascii: "n")
    static let r = UInt8(ascii: "r")
    static let s = UInt8(ascii: "s")
    static let t = UInt8(ascii: "t")
    static let u = UInt8(ascii: "u")

    static let A = UInt8(ascii: "A")
    static let B = UInt8(ascii: "B")
    static let C = UInt8(ascii: "C")
    static let D = UInt8(ascii: "D")
    static let E = UInt8(ascii: "E")
    static let F = UInt8(ascii: "F")

    static let zero  = UInt8(ascii: "0")
    static let one   = UInt8(ascii: "1")
    static let two   = UInt8(ascii: "2")
    static let three = UInt8(ascii: "3")
    static let four  = UInt8(ascii: "4")
    static let five  = UInt8(ascii: "5")
    static let six   = UInt8(ascii: "6")
    static let seven = UInt8(ascii: "7")
    static let eight = UInt8(ascii: "8")
    static let nine  = UInt8(ascii: "9")
}

private let ParserMaximumDepth = 512

/**
A pure Swift JSON parser. This parser is much faster than the
`NSJSONSerialization`-based parser (due to the overhead of having to
dynamically cast the Objective-C objects to determine their type); however,
it is much newer and has restrictions that the `NSJSONSerialization` parser
does not. Two restrictions in particular are that it requires UTF-8 data as
input and it does not allow trailing commas in arrays or dictionaries.
**/
public struct JSONParser {

    private enum Sign: IntMax {
        case Positive = 1
        case Negative = -1
    }

    private let input: UnsafeBufferPointer<UInt8>
    private let owner: Any?
    private var loc = 0
    private var depth = 0

    private init<T>(buffer: UnsafeBufferPointer<UInt8>, owner: T) {
        self.input = buffer
        self.owner = owner
    }

    public mutating func parse() throws -> JSON {
        let value = try parseValue()
        skipWhitespace()
        guard loc == input.count else {
            throw Error.EndOfStreamGarbage(offset: loc)
        }
        return value
    }

    private mutating func parseValue() throws -> JSON {
        guard depth <= ParserMaximumDepth else {
            throw Error.ExceededNestingLimit(offset: loc)
        }

        advancing: while loc < input.count {
            switch input[loc] {
            case Literal.LEFT_BRACKET:
                ++depth
                defer { --depth }
                return try decodeArray()

            case Literal.LEFT_BRACE:
                ++depth
                defer { --depth }
                return try decodeObject()

            case Literal.DOUBLE_QUOTE:
                return try decodeString()

            case Literal.f:
                return try decodeFalse()

            case Literal.n:
                return try decodeNull()

            case Literal.t:
                return try decodeTrue()

            case Literal.MINUS:
                return try decodeNumberNegative(loc)

            case Literal.zero:
                return try decodeNumberLeadingZero(loc)

            case Literal.one...Literal.nine:
                return try decodeNumberPreDecimalDigits(loc)

            case Literal.SPACE, Literal.TAB, Literal.RETURN, Literal.NEWLINE:
                ++loc

            default:
                break advancing
            }
        }
        
        throw Error.ValueInvalid(offset: loc, character: UnicodeScalar(input[loc]))
    }

    private mutating func skipWhitespace() {
        while loc < input.count {
            switch input[loc] {
            case Literal.SPACE, Literal.TAB, Literal.RETURN, Literal.NEWLINE:
                ++loc

            default:
                return
            }
        }
    }

    private mutating func decodeNull() throws -> JSON {
        guard loc.advancedBy(3, limit: input.count) != input.count else {
            throw Error.LiteralNilMisspelled(offset: loc)
        }

        if     input[loc+1] != Literal.u
            || input[loc+2] != Literal.l
            || input[loc+3] != Literal.l {
                throw Error.LiteralNilMisspelled(offset: loc)
        }

        loc += 4
        return .Null
    }

    private mutating func decodeTrue() throws -> JSON {
        guard loc.advancedBy(3, limit: input.count) != input.count else {
            throw Error.LiteralTrueMisspelled(offset: loc)
        }

        if     input[loc+1] != Literal.r
            || input[loc+2] != Literal.u
            || input[loc+3] != Literal.e {
            throw Error.LiteralTrueMisspelled(offset: loc)
        }

        loc += 4
        return .Bool(true)
    }

    private mutating func decodeFalse() throws -> JSON {
        guard loc.advancedBy(4, limit: input.count) != input.count else {
            throw Error.LiteralFalseMisspelled(offset: loc)
        }

        if     input[loc+1] != Literal.a
            || input[loc+2] != Literal.l
            || input[loc+3] != Literal.s
            || input[loc+4] != Literal.e {
            throw Error.LiteralFalseMisspelled(offset: loc)
        }

        loc += 5
        return .Bool(false)
    }

    private var stringDecodingBuffer = [UInt8]()
    private mutating func decodeString() throws -> JSON {
        let start = loc
        ++loc
        stringDecodingBuffer.removeAll(keepCapacity: true)
        while loc < input.count {
            switch input[loc] {
            case Literal.BACKSLASH:
                switch input[++loc] {
                case Literal.DOUBLE_QUOTE: stringDecodingBuffer.append(Literal.DOUBLE_QUOTE)
                case Literal.BACKSLASH:    stringDecodingBuffer.append(Literal.BACKSLASH)
                case Literal.SLASH:        stringDecodingBuffer.append(Literal.SLASH)
                case Literal.b:            stringDecodingBuffer.append(Literal.BACKSPACE)
                case Literal.f:            stringDecodingBuffer.append(Literal.FORMFEED)
                case Literal.r:            stringDecodingBuffer.append(Literal.RETURN)
                case Literal.t:            stringDecodingBuffer.append(Literal.TAB)
                case Literal.n:            stringDecodingBuffer.append(Literal.NEWLINE)
                case Literal.u:
                    guard let escaped = readUnicodeEscape(loc + 1) else {
                        throw Error.UnicodeEscapeInvalid(offset: loc)
                    }

                    stringDecodingBuffer.appendContentsOf(escaped)
                    loc += 4

                default:
                    throw Error.ControlCharacterUnrecognized(offset: loc)
                }
                ++loc

            case Literal.DOUBLE_QUOTE:
                ++loc
                stringDecodingBuffer.append(0)

                guard let string = (stringDecodingBuffer.withUnsafeBufferPointer {
                    String.fromCString(UnsafePointer($0.baseAddress))
                }) else {
                    throw Error.UnicodeEscapeInvalid(offset: start)
                }

                return .String(string)

            case let other:
                stringDecodingBuffer.append(other)
                ++loc
            }
        }

        throw Error.EndOfStreamUnexpected
    }

    private func readUnicodeEscape(from: Int) -> [UInt8]? {
        guard from + 4 <= input.count else {
            return nil
        }
        var codepoint: UInt16 = 0
        for i in from ..< from + 4 {
            let nibble: UInt16
            switch input[i] {
            case Literal.zero...Literal.nine:
                nibble = UInt16(input[i] - Literal.zero)

            case Literal.a...Literal.f:
                nibble = 10 + UInt16(input[i] - Literal.a)

            case Literal.A...Literal.F:
                nibble = 10 + UInt16(input[i] - Literal.A)

            default:
                return nil
            }
            codepoint = (codepoint << 4) | nibble
        }
        // UTF16-to-UTF8, via wikipedia
        if codepoint <= 0x007f {
            return [UInt8(codepoint)]
        } else if codepoint <= 0x07ff {
            return [0b11000000 | UInt8(codepoint >> 6),
                0b10000000 | UInt8(codepoint & 0x3f)]
        } else {
            return [0b11100000 | UInt8(codepoint >> 12),
                0b10000000 | UInt8((codepoint >> 6) & 0x3f),
                0b10000000 | UInt8(codepoint & 0x3f)]
        }
    }

    private mutating func decodeArray() throws -> JSON {
        let start = loc
        ++loc
        var items = [JSON]()

        while loc < input.count {
            skipWhitespace()

            if loc < input.count && input[loc] == Literal.RIGHT_BRACKET {
                ++loc
                return .Array(items)
            }

            if !items.isEmpty {
                guard loc < input.count && input[loc] == Literal.COMMA else {
                    throw Error.CollectionMissingSeparator(offset: start)
                }
                ++loc
            }

            items.append(try parseValue())
        }

        throw Error.EndOfStreamUnexpected
    }

    // Decoding objects can be recursive, so we have to keep more than one
    // buffer around for building up key/value pairs (to reduce allocations
    // when parsing large JSON documents).
    //
    // Rough estimate of the difference between this and using a fresh
    // [(String,JSON)] for the `pairs` variable in decodeObject() below is
    // about 12% on an iPhone 5.
    private struct DecodeObjectBuffers {
        var buffers = [[(String,JSON)]]()

        mutating func getBuffer() -> [(String,JSON)] {
            if !buffers.isEmpty {
                var buffer = buffers.removeLast()
                buffer.removeAll(keepCapacity: true)
                return buffer
            }
            return [(String,JSON)]()
        }

        mutating func putBuffer(buffer: [(String,JSON)]) {
            buffers.append(buffer)
        }
    }

    private var decodeObjectBuffers = DecodeObjectBuffers()

    private mutating func decodeObject() throws -> JSON {
        let start = loc
        ++loc
        var pairs = decodeObjectBuffers.getBuffer()

        while loc < input.count {
            skipWhitespace()

            if loc < input.count && input[loc] == Literal.RIGHT_BRACE {
                ++loc
                var obj = [String:JSON](minimumCapacity: pairs.count)
                for (k, v) in pairs {
                    obj[k] = v
                }
                decodeObjectBuffers.putBuffer(pairs)
                return .Dictionary(obj)
            }

            if !pairs.isEmpty {
                guard loc < input.count && input[loc] == Literal.COMMA else {
                    throw Error.CollectionMissingSeparator(offset: start)
                }
                ++loc

                skipWhitespace()
            }

            guard loc < input.count && input[loc] == Literal.DOUBLE_QUOTE else {
                throw Error.DictionaryMissingKey(offset: start)
            }

            let key = try decodeString().string()
            skipWhitespace()

            guard loc < input.count && input[loc] == Literal.COLON else {
                throw Error.CollectionMissingSeparator(offset: start)
            }
            ++loc

            pairs.append((key, try parseValue()))
        }

        throw Error.EndOfStreamUnexpected
    }

    private mutating func decodeNumberNegative(start: Int) throws -> JSON {
        ++loc
        guard loc < input.count else {
            throw Error.EndOfStreamUnexpected
        }

        switch input[loc] {
        case Literal.zero:
            return try decodeNumberLeadingZero(start, sign: .Negative)

        case Literal.one...Literal.nine:
            return try decodeNumberPreDecimalDigits(start, sign: .Negative)

        default:
            throw Error.NumberSymbolMissingDigits(offset: start)
        }
    }

    private mutating func decodeNumberLeadingZero(start: Int, sign: Sign = .Positive) throws -> JSON {
        ++loc
        guard loc < input.count else {
            return .Int(0)
        }

        switch (input[loc], sign) {
        case (Literal.PERIOD, _):
            return try decodeNumberDecimal(start, sign: sign, value: 0)

        case (_, .Negative):
            return .Double(-0.0)

        default:
            return .Int(0)
        }
    }

    private mutating func decodeNumberPreDecimalDigits(start: Int, sign: Sign = .Positive) throws -> JSON {
        var value: IntMax = 0

        advancing: while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                value = 10 * value + numericCast(c - Literal.zero)
                ++loc

            case Literal.PERIOD:
                return try decodeNumberDecimal(start, sign: sign, value: Double(value))

            case Literal.e, Literal.E:
                return try decodeNumberExponent(start, sign: sign, value: Double(value))

            default:
                break advancing
            }
        }

        return .Int(sign.rawValue * value)
    }

    private mutating func decodeNumberDecimal(start: Int, sign: Sign, value: Double) throws -> JSON {
        ++loc
        guard loc < input.count else {
            throw Error.EndOfStreamUnexpected
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return try decodeNumberPostDecimalDigits(start, sign: sign, value: value)

        default:
            throw Error.NumberMissingFractionalDigits(offset: start)
        }
    }

    private mutating func decodeNumberPostDecimalDigits(start: Int, sign: Sign, var value: Double) throws -> JSON {
        var position = 0.1

        advancing: while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                value += position * Double(c - Literal.zero)
                position /= 10
                ++loc

            case Literal.e, Literal.E:
                return try decodeNumberExponent(start, sign: sign, value: value)

            default:
                break advancing
            }
        }

        return .Double(Double(sign.rawValue) * value)
    }

    private mutating func decodeNumberExponent(start: Int, sign: Sign, value: Double) throws -> JSON {
        ++loc
        guard loc < input.count else {
            throw Error.EndOfStreamUnexpected
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return try decodeNumberExponentDigits(start, sign: sign, value: value, expSign: .Positive)

        case Literal.PLUS:
            return try decodeNumberExponentSign(start, sign: sign, value: value, expSign: .Positive)

        case Literal.MINUS:
            return try decodeNumberExponentSign(start, sign: sign, value: value, expSign: .Negative)

        default:
            throw Error.NumberSymbolMissingDigits(offset: start)
        }
    }

    private mutating func decodeNumberExponentSign(start: Int, sign: Sign, value: Double, expSign: Sign) throws -> JSON {
        ++loc
        guard loc < input.count else {
            throw Error.EndOfStreamUnexpected
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return try decodeNumberExponentDigits(start, sign: sign, value: value, expSign: expSign)

        default:
            throw Error.NumberSymbolMissingDigits(offset: start)
        }
    }

    private mutating func decodeNumberExponentDigits(start: Int, sign: Sign, value: Double, expSign: Sign) throws -> JSON {
        var exponent: Double = 0

        advancing: while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                exponent = exponent * 10 + Double(c - Literal.zero)
                ++loc

            default:
                break advancing
            }
        }

        return .Double(Double(sign.rawValue) * value * pow(10, Double(expSign.rawValue) * exponent))
    }
}

public extension JSONParser {

    init(utf8Data inData: NSData) {
        let data = inData.copy() as! NSData
        let buffer = UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length)
        self.init(buffer: buffer, owner: data)
    }

    init(string: String) {
        let codePoints = string.nulTerminatedUTF8
        let buffer = codePoints.withUnsafeBufferPointer { nulTerminatedBuffer in
            // don't want to include the nul termination in the buffer - trim it off
            UnsafeBufferPointer(start: nulTerminatedBuffer.baseAddress, count: nulTerminatedBuffer.count - 1)
        }
        self.init(buffer: buffer, owner: codePoints)
    }

}

extension JSONParser: JSONParserType {

    public static func createJSONFromData(data: NSData) throws -> JSON {
        var parser = JSONParser(utf8Data: data)
        return try parser.parse()
    }

}

// MARK: - Errors

extension JSONParser {

    /// Enumeration describing possible errors that occur while parsing a JSON
    /// document. Most errors include an associated `offset`, representing the
    /// offset into the UTF-8 characters making up the document where the error
    /// occurred.
    public enum Error: ErrorType {
        /// The parser ran out of data prematurely. This usually means a value
        /// was not escaped, such as a string literal not ending with a double
        /// quote.
        case EndOfStreamUnexpected
        
        /// Unexpected non-whitespace data was left around `offset` after
        /// parsing all valid JSON.
        case EndOfStreamGarbage(offset: Int)
        
        /// Too many nested objects or arrays occured at the literal started
        /// around `offset`.
        case ExceededNestingLimit(offset: Int)
        
        /// A `character` was not a valid start of a value around `offset`.
        case ValueInvalid(offset: Int, character: UnicodeScalar)
        
        /// Badly-formed Unicode escape sequence at `offset`. A Unicode escape
        /// uses the text "\u" followed by 4 hex digits, such as "\uF09F\uA684"
        /// to represent U+1F984, "UNICORN FACE".
        case UnicodeEscapeInvalid(offset: Int)
        
        /// Badly-formed control character around `offset`. JSON supports
        /// backslash-escaped double quotes, slashes, whitespace control codes,
        /// and Unicode escape sequences.
        case ControlCharacterUnrecognized(offset: Int)
        
        /// Invalid token, expected `null` around `offset`
        case LiteralNilMisspelled(offset: Int)
        
        /// Invalid token, expected `true` around `offset`
        case LiteralTrueMisspelled(offset: Int)
        
        /// Invalid token, expected `false` around `offset`
        case LiteralFalseMisspelled(offset: Int)
        
        /// Badly-formed collection at given `offset`, expected `,` or `:`
        case CollectionMissingSeparator(offset: Int)
        
        /// While parsing an object literal, a value was found without a key
        /// around `offset`. The start of a string literal was expected.
        case DictionaryMissingKey(offset: Int)
        
        /// Badly-formed number with no digits around `offset`. After a decimal
        /// point, a number must include some number of digits.
        case NumberMissingFractionalDigits(offset: Int)
        
        /// Badly-formed number with symbols ("-" or "e") but no following
        /// digits around `offset`.
        case NumberSymbolMissingDigits(offset: Int)
    }

}
