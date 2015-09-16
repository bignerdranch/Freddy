//
//  JSONValueDecodable.swift
//  BNRSwiftJSON
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
import Result

/**
    A protocol to provide functionality of creating a model object with a `JSONValue`.
*/
public protocol JSONDecodable {
    typealias Error: ErrorType

    /**
        Creates an instance of a model with a `JSONValue` instance.
    
        :param: value An instance of a `JSONValue` from which to build the instance.
    
        :returns: An optional instance of  `self`.
    */
    static func createWithJSON(value: JSON) -> Result<Self, Error>
}
