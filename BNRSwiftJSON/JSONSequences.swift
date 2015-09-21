//
//  JSONSequences.swift
//  BNRSwiftJSON
//
//  Created by John Gallagher on 6/3/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

extension SequenceType {

    /// Map a failable `transform` over `self`, capturing all transformations.
    /// - returns: Two arrays of the transformations that succeeded and failed,
    ///            respectively.
    /// - complexity: O(N).
    public func mapAndPartition<T>(@noescape transform: (Self.Generator.Element) throws -> T) -> (successes: [T], failures: [ErrorType]) {
        var successes = [T]()
        var failures = [ErrorType]()
        for element in self {
            do {
                successes.append(try transform(element))
            } catch {
                failures.append(error)
            }
        }
        return (successes, failures)
    }

}
