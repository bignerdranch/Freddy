//
//  CardSet.swift
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/19/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Freddy

struct CardSet {

    let name: String
    let code: String
    let gathererCode: String?
    let oldCode: String?
    let magicCardsInfoCode: String?
    let releaseDate: ReleaseDate
    let border: String
    let type: String
    let block: String?
    let isOnlineOnly: Bool
    let cards: [Card]

}

// MARK: - Freddy-style

extension CardSet: JSONDecodable {

    init(json: Freddy.JSON) throws {
        name               = try json.decode("name")
        code               = try json.decode("code")
        gathererCode       = try json.decode("gathererCode", ifNotFound: true)
        oldCode            = try json.decode("oldCode", ifNotFound: true)
        magicCardsInfoCode = try json.decode("magicCardsInfoCode", ifNotFound: true)
        releaseDate        = try json.decode("releaseDate")
        border             = try json.decode("border")
        type               = try json.decode("type")
        block              = try json.decode("block", ifNotFound: true)
        isOnlineOnly       = try json.decode("onlineOnly", or: false)
        cards              = try json.arrayOf("cards")
    }

}
