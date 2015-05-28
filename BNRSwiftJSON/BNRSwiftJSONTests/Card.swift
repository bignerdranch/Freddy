//
//  Card.swift
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

struct Card {

    private(set) var layout: String = ""
    private(set) var name: String = ""
    private(set) var manaCost: String = ""
    private(set) var cmc: Int = 0
    private(set) var colors: [String]?
    private(set) var type: String = ""
    private(set) var supertypes: [String]?
    private(set) var types: [String] = []
    private(set) var subtypes: [String]?
    private(set) var rarity: String = ""
    private(set) var text: String?
    private(set) var flavor: String?
    private(set) var artist: String = ""
    private(set) var number: String?
    private(set) var power: String?
    private(set) var toughness: String?
    private(set) var loyalty: Int?
    private(set) var multiverseID: Int?
    private(set) var variations: [Int]?
    private(set) var watermark: String?
    private(set) var border: String?
    private(set) var isTimeshifted: Bool = false
    private(set) var hand: Int?
    private(set) var life: Int?
    private(set) var isReserved: Bool = false
    private(set) var releaseDate: ReleaseDate?
    private(set) var isStarter: Bool = false

}

// MARK: - Argo-style

extension Card: Decodable {

    static func create(layout: String)(_ name: String)(_ manaCost: String?)(_ cmc: Int?)(_ colors: [String]?)(_ type: String)(_ supertypes: [String]?)(_ types: [String]?)(_ subtypes: [String]?)(_ rarity: String)(_ text: String?)(_ flavor: String?)(_ artist: String)(_ number: String?)(_ power: String?)(_ toughness: String?)(_ loyalty: Int?)(_ multiverseID: Int?)(_ variations: [Int]?)(_ watermark: String?)(_ border: String?)(_ isTimeshifted: Bool?)(_ hand: Int?)(_ life: Int?)(_ isReserved: Bool?)(_ releaseDate: ReleaseDate?)(_ isStarter: Bool?) -> Card {
        return Card(layout: layout, name: name, manaCost: manaCost ?? "", cmc: cmc ?? 0, colors: colors, type: type, supertypes: supertypes, types: types ?? [], subtypes: subtypes, rarity: rarity, text: text, flavor: flavor, artist: artist, number: number, power: power, toughness: toughness, loyalty: loyalty, multiverseID: multiverseID, variations: variations, watermark: watermark, border: border, isTimeshifted: isTimeshifted ?? false, hand: hand, life: life, isReserved: isReserved ?? false, releaseDate: releaseDate, isStarter: isStarter ?? false)
    }

    static func decode(j: Argo.JSON) -> Decoded<Card> {
        // Well, this is certainly silly, isn't it?
        let f1 = Card.create
            <^> j <| "layout"
            <*> j <| "name"
            <*> j <|? "manaCost"
            <*> j <|? "cmc"
            <*> j <||? "colors"
            <*> j <| "type"

        let f2 = f1
            <*> j <||? "supertypes"
            <*> j <||? "types"
            <*> j <||? "subtypes"
            <*> j <| "rarity"
            <*> j <|? "text"
            <*> j <|? "flavor"

        let f3 = f2
            <*> j <| "artist"
            <*> j <|? "number"
            <*> j <|? "power"
            <*> j <|? "toughness"
            <*> j <|? "loyalty"
            <*> j <|? "multiverseid"

        let f4 = f3
            <*> j <||? "variations"
            <*> j <|? "watermark"
            <*> j <|? "border"
            <*> j <|? "timeshifted"
            <*> j <|? "hand"
            <*> j <|? "life"

        let f5 = f4
            <*> j <|? "reserved"
            <*> j <|? "releaseDate"
            <*> j <|? "starter"

        return f5
    }

}

// TODO: - BNRSwiftJSON-style

extension Card: JSONDecodable {

    static func createWithJSON(json: BNRSwiftJSON.JSON) -> Result<Card> {
        let layout = json["layout"].string
        let name = json["name"].string
        let manaCost = fallback(json["manaCast"].string, "")
        let cmc = fallback(json["manaCast"].int, 0)
        let colors = optional(arrayOf(json["colors"], { $0.string }))
        let type = json["type"].string
        let supertypes = optional(arrayOf(json["supertypes"], { $0.string }))
        let types = fallback(arrayOf(json["types"], { $0.string }), [])
        let subtypes = optional(arrayOf(json["subtypes"], { $0.string }))
        let rarity = json["rarity"].string
        let text = optional(json["text"].string)
        let flavor = optional(json["flavor"].string)
        let artist = json["artist"].string
        let number = optional(json["number"].string)
        let power = optional(json["power"].string)
        let toughness = optional(json["toughness"].string)
        let loyalty = optional(json["loyalty"].int)
        let multiverseID = optional(json["multiverseid"].int)
        let variations = optional(arrayOf(json["variations"], { $0.int }))
        let watermark = optional(json["watermark"].string)
        let border = optional(json["border"].string)
        let isTimeshifted = fallback(json["timeshifted"].bool, false)
        let hand = optional(json["hand"].int)
        let life = optional(json["life"].int)
        let isReserved = fallback(json["reserved"].bool, false)
        let releaseDate = optional(json["releaseDate"].bind(ReleaseDate.createWithJSON))
        let isStarter = fallback(json["starter"].bool, false)

        return bindAll(layout, name, manaCost, cmc, colors, type, supertypes, types) { (layout, name, manaCost, cmc, colors, type, supertypes, types) -> Result<Card> in
            bindAll(subtypes, rarity, text, flavor, artist, number, power, toughness) { (subtypes, rarity, text, flavor, artist, number, power, toughness) -> Result<Card> in
                bindAll(loyalty, multiverseID, variations, watermark, border, isTimeshifted, hand, life) { (loyalty, multiverseID, variations, watermark, border, isTimeshifted, hand, life) -> Result<Card> in
                    mapAll(isReserved, releaseDate, isStarter) { (isReserved, releaseDate, isStarter) -> Card in
                        Card(layout: layout, name: name, manaCost: manaCost, cmc: cmc, colors: colors, type: type, supertypes: supertypes, types: types, subtypes: subtypes, rarity: rarity, text: text, flavor: flavor, artist: artist, number: number, power: power, toughness: toughness, loyalty: loyalty, multiverseID: multiverseID, variations: variations, watermark: watermark, border: border, isTimeshifted: isTimeshifted, hand: hand, life: life, isReserved: isReserved, releaseDate: releaseDate, isStarter: isStarter)
                    }
                }
            }
        }
    }

}

// TODO: - Pistachio-style/Lenses
