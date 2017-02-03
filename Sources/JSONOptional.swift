//
//  JSONOptional.swift
//  Freddy
//
//  Created by David House on 2/2/17.
//  Copyright © 2017 Big Nerd Ranch. All rights reserved.
//

import Foundation

// MARK: - OptionalLiteralConvertible
extension JSON {

    /// Create an instance from an Optional Double into either
    /// a .double or .null
    public init(_ optional: Double?) {
        
        guard let optional = optional else {
            self = .null
            return
        }
        
        self = .double(optional)
    }

    /// Create an instance from an Optional Int into either
    /// a .int or .null
    public init(_ optional: Int?) {
        
        guard let optional = optional else {
            self = .null
            return
        }
        
        self = .int(optional)
    }
    
    /// Create an instance from an Optional Bool into either
    /// a .bool or .null
    public init(_ optional: Bool?) {
        
        guard let optional = optional else {
            self = .null
            return
        }
        
        self = .bool(optional)
    }
    
    /// Create an instance from an Optional String into either
    /// a .string or .null
    public init(_ optional: String?) {
        
        guard let optional = optional else {
            self = .null
            return
        }
        
        self = .string(optional)
    }
}
