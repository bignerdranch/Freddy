//
//  JSONParser.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 4/18/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import Result

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

public struct JSONParser {

    private enum Sign: Int {
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

    public mutating func parse() -> Result<JSON, Error> {
        switch parseValue() {
        case let .Success(value):
            if loc != input.count {
                skipWhitespace()
                if loc != input.count {
                    return .Failure(Error.EndOfStreamGarbage(offset: loc))
                }
            }
            return .Success(value)

        case let .Failure(error):
            return .Failure(error)
        }
    }

    private mutating func increaseDepth<R>(@noescape fn: () -> R) -> R {
        ++depth
        let ret = fn()
        --depth
        return ret
    }

    private mutating func parseValue() -> Result<JSON, Error> {
        if depth > ParserMaximumDepth {
            return .Failure(Error.TooManyNestedObjects(offset: loc))
        }

        advancing: while loc < input.count {
            switch input[loc] {
            case Literal.LEFT_BRACKET:
                return increaseDepth {
                    decodeArray()
                }

            case Literal.LEFT_BRACE:
                return increaseDepth {
                    decodeObject()
                }

            case Literal.DOUBLE_QUOTE:
                return decodeString()

            case Literal.f:
                return decodeFalse()

            case Literal.n:
                return decodeNull()

            case Literal.t:
                return decodeTrue()

            case Literal.MINUS:
                return decodeNumberNegative(loc)

            case Literal.zero:
                return decodeNumberLeadingZero(loc, sign: .Positive)

            case Literal.one...Literal.nine:
                return decodeNumberPreDecimalDigits(loc, sign: .Positive)

            case Literal.SPACE, Literal.TAB, Literal.RETURN, Literal.NEWLINE:
                ++loc

            default:
                break advancing
            }
        }
        
        return .Failure(Error.ValueInvalid(offset: loc))
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

    private mutating func decodeNull() -> Result<JSON, Error> {
        if loc + 4 > input.count {
            return .Failure(Error.LiteralNilInvalid(offset: loc))
        }

        if     input[loc+1] != Literal.u
            || input[loc+2] != Literal.l
            || input[loc+3] != Literal.l {
                return .Failure(Error.LiteralNilInvalid(offset: loc))
        }

        loc += 4
        return .Success(.Null)
    }

    private mutating func decodeTrue() -> Result<JSON, Error> {
        if loc + 4 > input.count {
            return .Failure(Error.LiteralTrueInvalid(offset: loc))
        }

        if     input[loc+1] != Literal.r
            || input[loc+2] != Literal.u
            || input[loc+3] != Literal.e {
            return .Failure(Error.LiteralTrueInvalid(offset: loc))
        }

        loc += 4
        return .Success(.Bool(true))
    }

    private mutating func decodeFalse() -> Result<JSON, Error> {
        if loc + 5 > input.count {
            return .Failure(Error.LiteralFalseInvalid(offset: loc))
        }

        if     input[loc+1] != Literal.a
            || input[loc+2] != Literal.l
            || input[loc+3] != Literal.s
            || input[loc+4] != Literal.e {
            return .Failure(Error.LiteralFalseInvalid(offset: loc))
        }

        loc += 5
        return .Success(.Bool(false))
    }

    private var stringDecodingBuffer = [UInt8]()
    private mutating func decodeString() -> Result<JSON, Error> {
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
                    if let escaped = readUnicodeEscape(loc + 1) {
                        stringDecodingBuffer.appendContentsOf(escaped)
                        loc += 4
                    } else {
                        return .Failure(Error.EscapeUnfinished(offset: loc))
                    }

                default:
                    return .Failure(Error.EscapeUnfinished(offset: loc))
                }
                ++loc

            case Literal.DOUBLE_QUOTE:
                ++loc
                stringDecodingBuffer.append(0)
                return stringDecodingBuffer.withUnsafeBufferPointer { buffer -> Result<JSON, Error> in
                    if let s = String.fromCString(UnsafePointer<CChar>(buffer.baseAddress)) {
                        return .Success(.String(s))
                    } else {
                        return .Failure(Error.UnicodeEscapeInvalid(offset: start))
                    }
                }

            case let other:
                stringDecodingBuffer.append(other)
                ++loc
            }
        }

        return .Failure(Error.EndOfStreamUnexpected)
    }

    private func readUnicodeEscape(from: Int) -> [UInt8]? {
        if from + 4 > input.count {
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

    private mutating func decodeArray() -> Result<JSON, Error> {
        let start = loc
        ++loc
        var items = [JSON]()

        while loc < input.count {
            skipWhitespace()

            if loc < input.count && input[loc] == Literal.RIGHT_BRACKET {
                ++loc
                return .Success(.Array(items))
            }

            if !items.isEmpty {
                if loc < input.count && input[loc] == Literal.COMMA {
                    ++loc
                } else {
                    return .Failure(Error.LiteralMissingSeparator(offset: start))
                }
            }

            switch parseValue() {
            case .Success(let json):
                items.append(json)

            case let error:
                return error
            }
        }

        return .Failure(Error.EndOfStreamUnexpected)
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

    private mutating func decodeObject() -> Result<JSON, Error> {
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
                return .Success(.Dictionary(obj))
            }

            if !pairs.isEmpty {
                if loc < input.count && input[loc] == Literal.COMMA {
                    ++loc
                    skipWhitespace()
                } else {
                    return .Failure(Error.LiteralMissingSeparator(offset: start))
                }
            }

            let key: String
            if loc < input.count && input[loc] == Literal.DOUBLE_QUOTE {
                switch decodeString() {
                case .Success(let json):
                    key = json.string!
                case let error:
                    return error
                }
            } else {
                return .Failure(Error.LiteralMissingKey(offset: start))
            }

            skipWhitespace()
            if loc < input.count && input[loc] == Literal.COLON {
                ++loc
            } else {
                return .Failure(Error.LiteralMissingSeparator(offset: start))
            }

            switch parseValue() {
            case .Success(let json):
                let tuple = (key, json)
                pairs.append(tuple)
            case let error:
                return error
            }
        }

        return .Failure(Error.EndOfStreamUnexpected)
    }

    private mutating func decodeNumberNegative(start: Int) -> Result<JSON, Error> {
        if ++loc >= input.count {
            return .Failure(Error.EndOfStreamUnexpected)
        }

        switch input[loc] {
        case Literal.zero:
            return decodeNumberLeadingZero(start, sign: .Negative)

        case Literal.one...Literal.nine:
            return decodeNumberPreDecimalDigits(start, sign: .Negative)

        default:
            return .Failure(Error.LiteralNumberSymbolInvalid(offset: start))
        }
    }

    private mutating func decodeNumberLeadingZero(start: Int, sign: Sign = .Positive) -> Result<JSON, Error> {
        if ++loc >= input.count {
            return .Success(.Int(0))
        }

        switch (input[loc], sign) {
        case (Literal.PERIOD, _):
            return decodeNumberDecimal(start, sign: sign, value: 0)

        case (_, .Negative):
            return .Success(.Double(-0.0))

        default:
            return .Success(.Int(0))
        }
    }

    private mutating func decodeNumberPreDecimalDigits(start: Int, sign: Sign = .Positive) -> Result<JSON, Error> {
        var value = 0

        advancing: while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                value = 10 * value + Int(c - Literal.zero)
                ++loc

            case Literal.PERIOD:
                return decodeNumberDecimal(start, sign: sign, value: Double(value))

            case Literal.e, Literal.E:
                return decodeNumberExponent(start, sign: sign, value: Double(value))

            default:
                break advancing
            }
        }

        return .Success(.Int(sign.rawValue * value))
    }

    private mutating func decodeNumberDecimal(start: Int, sign: Sign, value: Double) -> Result<JSON, Error> {
        if ++loc >= input.count {
            return .Failure(Error.EndOfStreamUnexpected)
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return decodeNumberPostDecimalDigits(start, sign: sign, value: value)

        default:
            return .Failure(Error.LiteralNumberNoDigits(offset: start))
        }
    }

    private mutating func decodeNumberPostDecimalDigits(start: Int, sign: Sign, var value: Double) -> Result<JSON, Error> {
        var position = 0.1

        advancing: while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                value += position * Double(c - Literal.zero)
                position /= 10
                ++loc

            case Literal.e, Literal.E:
                return decodeNumberExponent(start, sign: sign, value: value)

            default:
                break advancing
            }
        }

        return .Success(.Double(Double(sign.rawValue) * value))
    }

    private mutating func decodeNumberExponent(start: Int, sign: Sign, value: Double) -> Result<JSON, Error> {
        if ++loc >= input.count {
            return .Failure(Error.EndOfStreamUnexpected)
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return decodeNumberExponentDigits(start, sign: sign, value: value, expSign: .Positive)

        case Literal.PLUS:
            return decodeNumberExponentSign(start, sign: sign, value: value, expSign: .Positive)

        case Literal.MINUS:
            return decodeNumberExponentSign(start, sign: sign, value: value, expSign: .Negative)

        default:
            return .Failure(Error.LiteralNumberExponentInvalid(offset: start))
        }
    }

    private mutating func decodeNumberExponentSign(start: Int, sign: Sign, value: Double, expSign: Sign) -> Result<JSON, Error> {
        if ++loc >= input.count {
            return .Failure(Error.EndOfStreamUnexpected)
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return decodeNumberExponentDigits(start, sign: sign, value: value, expSign: expSign)

        default:
            return .Failure(Error.LiteralNumberExponentInvalid(offset: start))
        }
    }

    private mutating func decodeNumberExponentDigits(start: Int, sign: Sign, value: Double, expSign: Sign) -> Result<JSON, Error> {
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

        return .Success(.Double(Double(sign.rawValue) * value * pow(10, Double(expSign.rawValue) * exponent)))
    }
}

public extension JSONParser {

    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.input = buffer
        self.owner = nil
    }

    init(utf8Data data: NSData) {
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

// MARK: - Errors

extension JSONParser {

    public enum Error: ErrorType {
        /// Unexpected end of file during string parse
        case EndOfStreamUnexpected
        /// Unexpected data after parsed JSON at given `offset`
        case EndOfStreamGarbage(offset: Int)
        /// Too many nested objects or arrays at given `offset`
        case TooManyNestedObjects(offset: Int)
        /// Invalid value around given `offset`
        case ValueInvalid(offset: Int)
        /// Badly formed string literal escape at given `offset`
        case EscapeUnfinished(offset: Int)
        /// Badly formed Unicode escape sequence at given `offset`
        case UnicodeEscapeInvalid(offset: Int)
        /// Invalid token at given `offset`, expected `null`
        case LiteralNilInvalid(offset: Int)
        /// Invalid token at given `offset`, expected `true`
        case LiteralTrueInvalid(offset: Int)
        /// Invalid token at given `offset`, expected `false`
        case LiteralFalseInvalid(offset: Int)
        /// Badly formed collection at given `offset`, expected `,` or `:`
        case LiteralMissingSeparator(offset: Int)
        /// No key for value in pair for object around given `offset`
        case LiteralMissingKey(offset: Int)
        /// Badly formed number with no digits around given `offset`
        case LiteralNumberNoDigits(offset: Int)
        /// Badly formed number with symbols but no digits around given `offset`
        case LiteralNumberSymbolInvalid(offset: Int)
        /// Badly formed number with exponent but no digits around given `offset`
        case LiteralNumberExponentInvalid(offset: Int)

    }

}
