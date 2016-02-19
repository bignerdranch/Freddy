//
//  Card.swift
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/19/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Freddy

struct Card {

    let layout: String
    let name: String
    let manaCost: String
    let cmc: Int
    let colors: [String]?
    let type: String
    let supertypes: [String]?
    let types: [String]
    let subtypes: [String]?
    let rarity: String
    let text: String?
    let flavor: String?
    let artist: String
    let number: String?
    let power: String?
    let toughness: String?
    let loyalty: Int?
    let multiverseID: Int?
    let variations: [Int]?
    let watermark: String?
    let border: String?
    let isTimeshifted: Bool
    let hand: Int?
    let life: Int?
    let isReserved: Bool
    let releaseDate: ReleaseDate?
    let isStarter: Bool

}

// MARK: - Freddy-style

extension Card: JSONDecodable {

    init(json: Freddy.JSON) throws {
        layout        = try json.decode("layout")
        name          = try json.decode("name")
        manaCost      = try json.decode("manaCost", or: "")
        cmc           = try json.decode("cmc", or: 0)
        colors        = try json.arrayOf("colors", ifNotFound: true)
        type          = try json.decode("type")
        supertypes    = try json.arrayOf("supertypes", ifNotFound: true)
        types         = try json.arrayOf("types", or: [])
        subtypes      = try json.arrayOf("subtypes", ifNotFound: true)
        rarity        = try json.decode("rarity")
        text          = try json.decode("text", ifNotFound: true)
        flavor        = try json.decode("flavor", ifNotFound: true)
        artist        = try json.decode("artist")
        number        = try json.decode("number", ifNotFound: true)
        power         = try json.decode("power", ifNotFound: true)
        toughness     = try json.decode("toughness", ifNotFound: true)
        loyalty       = try json.decode("loyalty", ifNotFound: true)
        multiverseID  = try json.decode("multiverseid", ifNotFound: true)
        variations    = try json.arrayOf("variations", ifNotFound: true)
        watermark     = try json.decode("watermark", ifNotFound: true)
        border        = try json.decode("border", ifNotFound: true)
        isTimeshifted = try json.decode("timeshifted", or: false)
        hand          = try json.decode("hand", ifNotFound: true)
        life          = try json.decode("life", ifNotFound: true)
        isReserved    = try json.decode("reserved", or: false)
        releaseDate   = try json.decode("releaseDate", ifNotFound: true)
        isStarter     = try json.decode("starter", or: false)
    }

}
