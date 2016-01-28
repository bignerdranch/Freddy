//
//  JSONEncodingDetector.swift
//  Freddy
//
//  Created by Robert Edwards on 1/27/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import Foundation

/// Struct for attempting to detect the Unicode encoding used with the data supplied to the JSONParser
struct JSONEncodingDetector {

    //// Attempts to detect the Unicode encoding used for a given set of data.
    ////
    //// This function initially looks for a Byte Order Mark in the following form:
    ////
    ////     Bytes     | Encoding Form
    //// --------------|----------------
    //// 00 00 FE FF   |	UTF-32, big-endian
    //// FF FE 00 00   |	UTF-32, little-endian
    //// FE FF         |	UTF-16, big-endian
    //// FF FE         |	UTF-16, little-endian
    //// EF BB BF      |	UTF-8
    ////
    //// If a BOM is not found then we detect using the following approach described in
    //// the JSON RFC http://www.ietf.org/rfc/rfc4627.txt:
    ////
    //// Since the first two characters of a JSON text will always be ASCII
    //// characters [RFC0020], it is possible to determine whether an octet
    //// stream is UTF-8, UTF-16 (BE or LE), or UTF-32 (BE or LE) by looking
    //// at the pattern of nulls in the first four octets.
    ////
    //// 00 00 00 xx  UTF-32BE
    //// 00 xx 00 xx  UTF-16BE
    //// xx 00 00 00  UTF-32LE
    //// xx 00 xx 00  UTF-16LE
    //// xx xx xx xx  UTF-8
    ////
    //// - parameter header: The array of data being read and evaluated.
    //// - returns: The NSStringEncoding that was detected.
    static func detectEncoding(header: Slice<UnsafeBufferPointer<UInt8>>) -> NSStringEncoding {
        if let encoding = JSONEncodingDetector.encodingFromBOM(header) {
            return encoding
        } else {
            if header.count >= 4 {
                switch (header[0], header[1], header[2], header[3]) {
                case (0, 0, 0, _):
                    return NSUTF32BigEndianStringEncoding
                case (_, 0, 0, 0):
                    return NSUTF32LittleEndianStringEncoding
                case (0, _, 0, _):
                    return NSUTF16BigEndianStringEncoding
                case (_, 0, _, 0):
                    return NSUTF16LittleEndianStringEncoding
                default:
                    break
                }
            } else if header.count >= 2 {
                switch (header[0], header[1]) {
                case (0, _):
                    return NSUTF16BigEndianStringEncoding
                case (_, 0):
                    return NSUTF16LittleEndianStringEncoding
                default:
                    break
                }
            }
            return NSUTF8StringEncoding
        }
    }

    private static func encodingFromBOM(header: Slice<UnsafeBufferPointer<UInt8>>) -> NSStringEncoding? {
        let length = header.count
        if length >= 2 {
            switch (header[0], header[1]) {
            case (0xEF, 0xBB):
                if length >= 3 && header[2] == 0xBF {
                    return NSUTF8StringEncoding
                }
            case (0x00, 0x00):
                if length >= 4 && header[2] == 0xFE && header[3] == 0xFF {
                    return NSUTF32BigEndianStringEncoding
                }
            case (0xFF, 0xFE):
                if length >= 4 && header[2] == 0 && header[3] == 0 {
                    return NSUTF32LittleEndianStringEncoding
                }
                return NSUTF16LittleEndianStringEncoding
            case (0xFE, 0xFF):
                return NSUTF16BigEndianStringEncoding
            default:
                break
            }
        }
        return nil
    }
}
