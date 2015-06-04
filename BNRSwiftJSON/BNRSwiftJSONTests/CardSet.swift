//
//  CardSet.swift
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/19/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. Licensed under MIT.
//

import Foundation
import Argo
import Runes
import BNRSwiftJSON
import Result

struct CardSet {

    private(set) var name: String = ""
    private(set) var code: String = ""
    private(set) var gathererCode: String?
    private(set) var oldCode: String?
    private(set) var magicCardsInfoCode: String?
    private(set) var releaseDate: ReleaseDate
    private(set) var border: String = ""
    private(set) var type: String = ""
    private(set) var block: String?
    private(set) var isOnlineOnly: Bool = false
    private(set) var cards: [Card] = []

}

// MARK: - Argo-style

extension CardSet: Decodable {

    static func create(name: String)(_ code: String)(_ gathererCode: String?)(_ oldCode: String?)(_ magicCardsInfoCode: String?)(_ releaseDate: ReleaseDate)(_ border: String)(_ type: String)(_ block: String?)(_ isOnlineOnly: Bool?)(_ cards: [Card]) -> CardSet {
        return CardSet(name: name, code: code, gathererCode: gathererCode, oldCode: oldCode, magicCardsInfoCode: magicCardsInfoCode, releaseDate: releaseDate, border: border, type: type, block: block, isOnlineOnly: isOnlineOnly ?? false, cards: cards)
    }

    static func decode(j: Argo.JSON) -> Decoded<CardSet> {
        let f1 = CardSet.create
            <^> j <| "name"
            <*> j <| "code"
            <*> j <|? "gathererCode"
            <*> j <|? "oldCode"
            <*> j <|? "magicCardsInfoCode"
            <*> j <| "releaseDate"

        let f2 = f1
            <*> j <| "border"
            <*> j <| "type"
            <*> j <|? "block"
            <*> j <|? "onlineOnly"
            <*> j <|| "cards"

        return f2
    }

}

// MARK: - BNRSwiftJSON-style

extension CardSet {

    static func createWithJSON(json: BNRSwiftJSON.JSON) -> Result<CardSet> {
        let name = json["name"].string
        let code = json["code"].string
        let gathererCode = optional(json["gathererCode"].string)
        let oldCode = optional(json["oldCode"].string)
        let magicCardsInfoCode = optional(json["magicCardsInfoCode"].string)
        let releaseDate = json["releaseDate"].bind(ReleaseDate.createWithJSON)
        let border = json["border"].string
        let type = json["type"].string
        let block = optional(json["block"].string)
        let isOnlineOnly = fallback(json["onlineOnly"].bool, false)
        let cards = arrayOf(json["cards"]) as Result<[Card]>

        return bindAll(name, code, gathererCode, oldCode, magicCardsInfoCode, releaseDate, border, type) { (name, code, gathererCode, oldCode, magicCardsInfoCode, releaseDate, border, type) in
            mapAll(block, isOnlineOnly, cards) { (block, isOnlineOnly, cards) in
                CardSet(name: name, code: code, gathererCode: gathererCode, oldCode: oldCode, magicCardsInfoCode: magicCardsInfoCode, releaseDate: releaseDate, border: border, type: type, block: block, isOnlineOnly: isOnlineOnly, cards: cards)
            }
        }
    }

}
