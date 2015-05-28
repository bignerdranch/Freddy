//
//  Dictionary.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/11/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation

extension Dictionary {
    
    func map<NewValue>(@noescape transform: (Key, Value) -> NewValue) -> Dictionary<Key, NewValue> {
        let initial = Dictionary<Key, NewValue>(minimumCapacity: count)
        return reduce(self, initial) { (var dictionary, element) in
            dictionary[element.0] = transform(element.0, element.1)
            return dictionary
        }
    }
    
}
