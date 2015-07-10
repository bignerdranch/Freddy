//
//  BNRTestAssertions.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 4/24/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import Foundation
import XCTest

private struct EquatableOptional<T: Equatable>: Equatable, DebugPrintable {
    var debugDescription: String {
        return value.debugDescription
    }
    let value: T?
    init(_ value: T?) {
        self.value = value
    }
}

private func ==<T>(lhs: EquatableOptional<T>, rhs: EquatableOptional<T>) -> Bool {
    return lhs.value == rhs.value
}

// pass through to existing XCTAssertEqual overloads
func BNRAssertEqual<T : Equatable>(@autoclosure expression1:  () -> T, @autoclosure expression2:  () -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertEqual<T : Equatable>(@autoclosure expression1:  () -> ArraySlice<T>, @autoclosure expression2:  () -> ArraySlice<T>, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertEqual<T : Equatable>(@autoclosure expression1:  () -> ContiguousArray<T>, @autoclosure expression2:  () -> ContiguousArray<T>, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertEqual<T : Equatable>(@autoclosure expression1:  () -> [T], @autoclosure expression2:  () -> [T], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertEqual<T, U : Equatable>(@autoclosure expression1:  () -> [T : U], @autoclosure expression2:  () -> [T : U], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(expression1(), expression2(), message, file: file, line: line)
}

// custom overloads to support optionals
func BNRAssertEqual<T : Equatable>(@autoclosure expression1:  () -> T?, @autoclosure expression2:  () -> T?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(EquatableOptional(expression1()), EquatableOptional(expression2()), message, file: file, line: line)
}

func BNRAssertEqual<T : Equatable>(@autoclosure expression1:  () -> [T?], @autoclosure expression2:  () -> [T?], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let a1 = expression1().map { EquatableOptional($0) }
    let a2 = expression2().map { EquatableOptional($0) }
    XCTAssertEqual(a1, a2, message, file: file, line: line)
}

// pass through to existing XCTAssertNotEqual overloads
func BNRAssertNotEqual<T : Equatable>(@autoclosure expression1:  () -> T, @autoclosure expression2:  () -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertNotEqual<T : Equatable>(@autoclosure expression1:  () -> ArraySlice<T>, @autoclosure expression2:  () -> ArraySlice<T>, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertNotEqual<T : Equatable>(@autoclosure expression1:  () -> ContiguousArray<T>, @autoclosure expression2:  () -> ContiguousArray<T>, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertNotEqual<T : Equatable>(@autoclosure expression1:  () -> [T], @autoclosure expression2:  () -> [T], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqual(expression1(), expression2(), message, file: file, line: line)
}

func BNRAssertNotEqual<T, U : Equatable>(@autoclosure expression1:  () -> [T : U], @autoclosure expression2:  () -> [T : U], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqual(expression1(), expression2(), message, file: file, line: line)
}

// custom overloads to support optionals
func BNRAssertNotEqual<T : Equatable>(@autoclosure expression1:  () -> T?, @autoclosure expression2:  () -> T?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqual(EquatableOptional(expression1()), EquatableOptional(expression2()), message, file: file, line: line)
}

func BNRAssertNotEqual<T : Equatable>(@autoclosure expression1:  () -> [T?], @autoclosure expression2:  () -> [T?], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let a1 = expression1().map { EquatableOptional($0) }
    let a2 = expression2().map { EquatableOptional($0) }
    XCTAssertNotEqual(a1, a2, message, file: file, line: line)
}

// pass through to existing XCTAssertEqualWithAccuracy
func BNRAssertEqualWithAccuracy<T : FloatingPointType>(@autoclosure expression1:  () -> T, @autoclosure expression2:  () -> T, accuracy: T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqualWithAccuracy(expression1(), expression2(), accuracy, message, file: file, line: line)
}

// custom overload to support optionals
func BNRAssertEqualWithAccuracy<T : FloatingPointType>(@autoclosure expression1:  () -> T?, @autoclosure expression2:  () -> T?, accuracy: T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let t1 = expression1()
    let t2 = expression2()

    if let t1 = t1, t2 = t2 {
        XCTAssertEqualWithAccuracy(t1, t2, accuracy, message, file: file, line: line)
    } else {
        // This will fail unless both are nil, but it will give a reasonable error message
        BNRAssertEqual(t1, t2, message, file: file, line: line)
    }
}

// pass through to existing XCTAssertNotEqualWithAccuracy
func BNRAssertNotEqualWithAccuracy<T : FloatingPointType>(@autoclosure expression1:  () -> T, @autoclosure expression2:  () -> T, accuracy: T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertNotEqualWithAccuracy(expression1(), expression2(), accuracy, message, file: file, line: line)
}

// custom overload to support optionals
func BNRAssertNotEqualWithAccuracy<T : FloatingPointType>(@autoclosure expression1:  () -> T?, @autoclosure expression2:  () -> T?, accuracy: T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let t1 = expression1()
    let t2 = expression2()

    if let t1 = t1, t2 = t2 {
        XCTAssertNotEqualWithAccuracy(t1, t2, accuracy, message, file: file, line: line)
    } else {
        // This will fail unless both are nil, but it will give a reasonable error message
        BNRAssertNotEqual(t1, t2, message, file: file, line: line)
    }
}
