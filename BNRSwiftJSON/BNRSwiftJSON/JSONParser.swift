//
//  JSONParser.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 4/18/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation
import Result

public func JSONFromString(s: String) -> Result<JSON> {
    return s.nulTerminatedUTF8.withUnsafeBufferPointer { nulTerminatedBuffer in
        // don't want to include the nul termination in the buffer - trim it off
        let buffer = UnsafeBufferPointer(start: nulTerminatedBuffer.baseAddress, count: nulTerminatedBuffer.count - 1)
        return JSONFromUnsafeBufferPointer(buffer)
    }
}

public func JSONFromUTF8Data(data: NSData) -> Result<JSON> {
    let buffer = UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length)
    return JSONFromUnsafeBufferPointer(buffer)
}

public func JSONFromUnsafeBufferPointer(buffer: UnsafeBufferPointer<UInt8>) -> Result<JSON> {
    var parser = Parser(input: buffer)
    switch parser.parse() {
    case .Ok(let json):
        return Result(success: json)
    case .Err(let error):
        return Result(failure: error)
    }
}

private func makeParseError(reason: String) -> Parser.Result {
    return .Err(JSON.makeError(.CouldNotParseJSON, problem: reason))
}

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

let ParserMaximumDepth = 512

private struct Parser {
    enum Result {
        case Ok(JSON)
        case Err(NSError)
    }

    enum Sign: Double {
        case Positive = 1.0
        case Negative = -1.0
    }

    let input: UnsafeBufferPointer<UInt8>
    var loc = 0

    var depth = 0

    init(input: UnsafeBufferPointer<UInt8>) {
        self.input = input
    }

    mutating func parse() -> Result {
        switch parseValue() {
        case let .Ok(value):
            if loc != input.count {
                skipWhitespace()
                if loc != input.count {
                    return makeParseError("unexpected data after parsed JSON")
                }
            }
            return .Ok(value)

        case let result:
            return result
        }
    }

    mutating func increaseDepth<R>(@noescape fn: () -> R) -> R {
        ++depth
        let ret = fn()
        --depth
        return ret
    }

    mutating func parseValue() -> Result {
        if depth > ParserMaximumDepth {
            return makeParseError("Exceeded nesting limit around position character \(loc)")
        }

        while loc < input.count {
            switch input[loc] {
            case Literal.LEFT_BRACKET:
                return increaseDepth(decodeArray)

            case Literal.LEFT_BRACE:
                return increaseDepth(decodeObject)

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
                return makeParseError("did not find start of valid JSON data")
            }
        }
        
        return makeParseError("Invalid value around character \(loc)")
    }

    mutating func skipWhitespace() {
        while loc < input.count {
            switch input[loc] {
            case Literal.SPACE, Literal.TAB, Literal.RETURN, Literal.NEWLINE:
                ++loc

            default:
                return
            }
        }
    }

    mutating func decodeNull() -> Result {
        if loc + 4 > input.count {
            return makeParseError("invalid token at position \(loc) - expected `null`")
        }

        if     input[loc+1] != Literal.u
            || input[loc+2] != Literal.l
            || input[loc+3] != Literal.l {
                return makeParseError("invalid token at position \(loc) - expected `null`")
        }

        loc += 4
        return .Ok(.Null)
    }

    mutating func decodeTrue() -> Result {
        if loc + 4 > input.count {
            return makeParseError("invalid token at position \(loc) - expected `true`")
        }

        if     input[loc+1] != Literal.r
            || input[loc+2] != Literal.u
            || input[loc+3] != Literal.e {
            return makeParseError("invalid token at position \(loc) - expected `true`")
        }

        loc += 4
        return .Ok(.Bool(true))
    }

    mutating func decodeFalse() -> Result {
        if loc + 5 > input.count {
            return makeParseError("invalid token at position \(loc) - expected `false`")
        }

        if     input[loc+1] != Literal.a
            || input[loc+2] != Literal.l
            || input[loc+3] != Literal.s
            || input[loc+4] != Literal.e {
            return makeParseError("invalid token at position \(loc) - expected `false`")
        }

        loc += 5
        return .Ok(.Bool(false))
    }

    var stringDecodingBuffer = [UInt8]()
    mutating func decodeString() -> Result {
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
                        stringDecodingBuffer.extend(escaped)
                        loc += 4
                    } else {
                        return makeParseError("invalid unicode escape sequence at position \(loc)")
                    }

                default:
                    return makeParseError("invalid escape sequence at position \(loc)")
                }
                ++loc

            case Literal.DOUBLE_QUOTE:
                ++loc
                stringDecodingBuffer.append(0)
                return stringDecodingBuffer.withUnsafeBufferPointer { buffer -> Result in
                    if let s = String.fromCString(UnsafePointer<CChar>(buffer.baseAddress)) {
                        return .Ok(.String(s))
                    } else {
                        return makeParseError("invalid string at position \(start) - possibly malformed unicode characters")
                    }
                }

            case let other:
                stringDecodingBuffer.append(other)
                ++loc
            }
        }

        return makeParseError("unexpected end of data while parsing string at position \(start)")
    }

    func readUnicodeEscape(from: Int) -> [UInt8]? {
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

    mutating func decodeArray() -> Result {
        let start = loc
        ++loc
        var items = [JSON]()

        while loc < input.count {
            skipWhitespace()

            if loc < input.count && input[loc] == Literal.RIGHT_BRACKET {
                ++loc
                return .Ok(.Array(items))
            }

            if !items.isEmpty {
                if loc < input.count && input[loc] == Literal.COMMA {
                    ++loc
                } else {
                    return makeParseError("invalid array at position \(start) - missing `,` between elements")
                }
            }

            switch parseValue() {
            case .Ok(let json):
                items.append(json)

            case let error:
                return error
            }
        }

        return makeParseError("unexpected end of data while parsing array at position \(start)")
    }

    // Decoding objects can be recursive, so we have to keep more than one
    // buffer around for building up key/value pairs (to reduce allocations
    // when parsing large JSON documents).
    //
    // Rough estimate of the difference between this and using a fresh
    // [(String,JSON)] for the `pairs` variable in decodeObject() below is
    // about 12% on an iPhone 5.
    struct DecodeObjectBuffers {
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

    var decodeObjectBuffers = DecodeObjectBuffers()

    mutating func decodeObject() -> Result {
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
                return .Ok(.Dictionary(obj))
            }

            if !pairs.isEmpty {
                if loc < input.count && input[loc] == Literal.COMMA {
                    ++loc
                    skipWhitespace()
                } else {
                    return makeParseError("invalid object at position \(start) - missing `,` between elements")
                }
            }

            let key: String
            if loc < input.count && input[loc] == Literal.DOUBLE_QUOTE {
                switch decodeString() {
                case .Ok(let json):
                    key = json.string!
                case let error:
                    return error
                }
            } else {
                return makeParseError("invalid object at position \(start) - missing key")
            }

            skipWhitespace()
            if loc < input.count && input[loc] == Literal.COLON {
                ++loc
            } else {
                return makeParseError("invalid object at position \(start) - missing `:` between key and value")
            }

            switch parseValue() {
            case .Ok(let json):
                let tuple = (key, json)
                pairs.append(tuple)
            case let error:
                return error
            }
        }

        return makeParseError("unexpected end of data while parsing object at position \(start)")
    }

    mutating func decodeNumberNegative(start: Int) -> Result {
        if ++loc >= input.count {
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }

        switch input[loc] {
        case Literal.zero:
            return decodeNumberLeadingZero(start, sign: .Negative)

        case Literal.one...Literal.nine:
            return decodeNumberPreDecimalDigits(start, sign: .Negative)

        default:
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }
    }

    mutating func decodeNumberLeadingZero(start: Int, sign: Sign) -> Result {
        if ++loc >= input.count {
            return .Ok(.Number(0))
        }

        switch input[loc] {
        case Literal.PERIOD:
            return decodeNumberDecimal(start, sign: sign, value: 0)

        default:
            return .Ok(.Number(0))
        }
    }

    mutating func decodeNumberPreDecimalDigits(start: Int, sign: Sign) -> Result {
        var value: Double = 0

        while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                value = 10 * value + Double(c - Literal.zero)
                ++loc

            case Literal.PERIOD:
                return decodeNumberDecimal(start, sign: sign, value: value)

            case Literal.e, Literal.E:
                return decodeNumberExponent(start, sign: sign, value: value)

            default:
                return .Ok(.Number(sign.rawValue * value))
            }
        }
        return .Ok(.Number(sign.rawValue * value))
    }

    mutating func decodeNumberDecimal(start: Int, sign: Sign, value: Double) -> Result {
        if ++loc >= input.count {
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return decodeNumberPostDecimalDigits(start, sign: sign, value: value)

        default:
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }
    }

    mutating func decodeNumberPostDecimalDigits(start: Int, sign: Sign, var value: Double) -> Result {
        var position = 0.1

        while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                value += position * Double(c - Literal.zero)
                position /= 10
                ++loc

            case Literal.e, Literal.E:
                return decodeNumberExponent(start, sign: sign, value: value)

            default:
                return .Ok(.Number(sign.rawValue * value))
            }
        }
        return .Ok(.Number(sign.rawValue * value))
    }

    mutating func decodeNumberExponent(start: Int, sign: Sign, value: Double) -> Result {
        if ++loc >= input.count {
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }

        switch input[loc] {
        case Literal.zero...Literal.nine:
            return decodeNumberExponentDigits(start, sign: sign, value: value, expSign: .Positive)

        case Literal.PLUS:
            return decodeNumberExponentSign(start, sign: sign, value: value, expSign: .Positive)

        case Literal.MINUS:
            return decodeNumberExponentSign(start, sign: sign, value: value, expSign: .Negative)

        default:
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }
    }

    mutating func decodeNumberExponentSign(start: Int, sign: Sign, value: Double, expSign: Sign) -> Result {
        if ++loc >= input.count {
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }
        switch input[loc] {
        case Literal.zero...Literal.nine:
            return decodeNumberExponentDigits(start, sign: sign, value: value, expSign: expSign)

        default:
            return makeParseError("unexpected end of data while parsing number at position \(start)")
        }
    }

    mutating func decodeNumberExponentDigits(start: Int, sign: Sign, value: Double, expSign: Sign) -> Result {
        var exponent: Double = 0
        while loc < input.count {
            let c = input[loc]
            switch c {
            case Literal.zero...Literal.nine:
                exponent = exponent * 10 + Double(c - Literal.zero)
                ++loc

            default:
                return .Ok(.Number(sign.rawValue * value * pow(10, expSign.rawValue * exponent)))
            }
        }
        return .Ok(.Number(sign.rawValue * value * pow(10, expSign.rawValue * exponent)))
    }
}
