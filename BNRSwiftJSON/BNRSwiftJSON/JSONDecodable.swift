//
//  JSONValueDecodable.swift
//  Test
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation
import Result

/**
    A protocol to provide functionality of creating a model object with a `JSONValue`.
*/
public protocol JSONDecodable {
    /**
        Creates an instance of a model with a `JSONValue` instance.
    
        :param: value An instance of a `JSONValue` from which to build the instance.
    
        :returns: An optional instance of  `self`.
    */
    static func createWithJSON(value: JSON) -> Result<Self>
}