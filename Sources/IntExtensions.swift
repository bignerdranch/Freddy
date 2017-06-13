//
//  IntExtensions.swift
//  Freddy
//
//  Created by Volodymyr  Gorbenko on 2/6/17.
//  Copyright © 2017 Big Nerd Ranch. All rights reserved.
//

import Foundation

#if swift(>=3.2)
#else

public enum ArithmeticOverflow {

  public init(_ overflow: Bool) {
    self = overflow ? .overflow : .none
  }

  case none
  case overflow
}

extension Int {

  func multipliedReportingOverflow(by other: Int) -> (partialValue: Int, overflow: ArithmeticOverflow) {
    let (exponent, overflow) = Int.multiplyWithOverflow(self, other)
    return (exponent, ArithmeticOverflow(overflow))
  }

  func addingReportingOverflow(_ other: Int) -> (partialValue: Int, overflow: ArithmeticOverflow) {
    let (exponent, overflow) = Int.addWithOverflow(self, other)
    return (exponent, ArithmeticOverflow(overflow))
  }
}

#endif
