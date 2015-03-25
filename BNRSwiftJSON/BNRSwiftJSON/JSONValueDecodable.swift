//
//  JSONValueDecodable.swift
//  Test
//
//  Created by Matthew D. Mathias on 3/24/15.
//  Copyright (c) 2015 BigNerdRanch. All rights reserved.
//

import Foundation

/**
    A protocol to provide functionality of creating a model object with a `JSONValue`.
*/
public protocol JSONValueDecodable {
    /**
        Creates an instance of a model with a `JSONValue` instance.
    
        :param: value An instance of a `JSONValue` from which to build the instance.
    
        :returns: An optional instance of  `self`.
    */
    static func createWithJSONValue(value: JSONValue) -> Result<Self>
}