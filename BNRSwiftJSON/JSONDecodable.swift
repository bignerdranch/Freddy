//
//  JSONDecodable.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

/// A protocol to provide functionality of creating a model object with a `JSON`
/// value.
public protocol JSONDecodable {
    
    /// Creates an instance of the model with a `JSON` instance.
    /// - parameter value: An instance of a `JSON` value from which to
    ///             construct an instance of the implementing type.
    /// - throws: Any `JSON.Error` for errors derived from inspecting the
    ///           `JSON` value, or any other error involved in decoding.
    init(json: JSON) throws
    
}
