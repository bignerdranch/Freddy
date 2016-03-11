//
//  JSONSubscriptingTests.swift
//  Freddy
//
//  Created by Matthew Mathias on 2/21/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Freddy

class JSONSubscriptingTests: XCTestCase {
    
    var json: JSON!
    
    override func setUp() {
        super.setUp()
        
        json = JSON.Dictionary([
            "residents": [
                ["name": "Matt", "age": 33, "hasPet": false, "rent": .Null],
                ["name": "Drew", "hasPet": true, "rent": 1234.5],
                ["name": "Pat", "age": 28, "hasPet": .Null]
            ]
            ])
    }
    
    func testThatArrayOfProducesResidents() {
        do {
            let residents = try json.arrayOf("residents", type: Resident.self)
            let residentsNames = residents.map { $0.name }
            XCTAssertEqual(residentsNames.count, 3, "There should be 3 residents.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsDecodes() {
        do {
            let firstResident = try json.decode("residents", 0, alongPath: [.NullBecomesNil, .MissingKeyBecomesNil], type: Resident.self)
            XCTAssertNotNil(firstResident)
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsProducesOptionalForNotFound() {
        do {
            let residents = try json.arrayOf("residents", type: Resident.self)
            XCTAssertNil(residents[1].age, "Drew's `age` should be nil.")
        } catch {
            XCTFail("There should be no error.")
        }
    }
    
    func testNullOptionsProducesOptionalForNullOrNotFound() {
        do {
            let residents = try json.arrayOf("residents", type: Resident.self)
            XCTAssertNil(residents.first?.rent, "Matt should have nil `rent`.")
            XCTAssertEqual(residents[1].rent!, 1234.5, "Drew's `rent` should equal 1234.5.")
            XCTAssertNil(residents.last?.rent, "Pat should have nil `rent`.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsIndexOutOfBoundsProducesOptional() {
        do {
            let residentOutOfBounds = try json.decode("residents", 4, alongPath: .MissingKeyBecomesNil, type: Resident.self)
            XCTAssertNil(residentOutOfBounds)
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testArrayOfJSONIntAndNullCreatesOptionalWhenDetectNull() {
        let testJSON: JSON = [1,2,.Null,4]
        do {
            _ = try testJSON.arrayOf(alongPath: .NullBecomesNil, type: Int.self)
            XCTFail("`testJSON.arrayOf(_:options:type:)` should throw.")
        } catch let JSON.Error.ValueNotConvertible(value, type) {
            XCTAssert(type == Int.self, "value (\(value)) is not equal to \(type).")
        } catch {
            XCTFail("There should be no error: \(error)")
        }
    }

    func testArrayProducesOptionalWhenNotFoundOrNull() {
        let testJSON: JSON = ["integers": .Null]
        do {
            let test1 = try testJSON.array("integers", alongPath: .NullBecomesNil)
            let test2 = try testJSON.array("residents", alongPath: .MissingKeyBecomesNil)
            XCTAssertNil(test1, "Test1 should be nil.")
            XCTAssertNil(test2, "Test2 should be nil.")
        } catch {
            XCTFail("There should be no error: \(error)")
        }
    }
    
    func testDictionaryProducesOptionalWhenNotFoundOrNull() {
        let testJSON: JSON = ["integers": .Null]
        do {
            let test1 = try testJSON.dictionary("integers", alongPath: .NullBecomesNil)
            let test2 = try testJSON.dictionary("residents", alongPath: .MissingKeyBecomesNil)
            XCTAssertNil(test1, "Test1 should be nil.")
            XCTAssertNil(test2, "Test2 should be nil.")
        } catch {
            XCTFail("There should be no error: \(error)")
        }
    }
    
    func testJSONDictionaryUnexpectedSubscript() {
        do {
            _ = try json.decode(1, type: Resident.self)
            XCTFail("Should throw error.")
        } catch JSON.Error.UnexpectedSubscript(type: let theType) {
            XCTAssertTrue(theType is Int.Type)
        } catch {
            XCTFail("Didn't catch the right error: \(error).")
        }
    }
    
    func testJSONIndexSubscript() {
        let residents = json["residents"]
        XCTAssertNotNil(residents)
    }
    
    func testJSONKeySubscript() {
        let matt = json["residents"]?[0]
        XCTAssertNotNil(matt)
    }
    
    func testDecodeOr() {
        do {
            let outOfBounds = try json.decode("residents", 4, or: Resident(name: "NA", age: 30, hasPet: false, rent: 0))
            XCTAssertTrue(outOfBounds.name == "NA")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testDoubleOr() {
        do {
            let rent = try json.double("residents", 2, "rent", or: 0)
            XCTAssertTrue(rent == 0, "Rent should be free.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testStringOr() {
        do {
            let nickname = try json.string("residents", 0, "nickname", or: "DubbaDubs")
            XCTAssertTrue(nickname == "DubbaDubs")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testIntOr() {
        do {
            let age = try json.int("residents", 1, "age", or: 21)
            XCTAssertTrue(age == 21, "Forever young!")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testBoolOr() {
        do {
            let hasSpouse = try json.bool("residents", 1, "hasSpouse", or: false)
            XCTAssertFalse(hasSpouse, "No spouse")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }

    func testArrayOr() {
        do {
            let testJSON: JSON = ["pets": .Null]
            let defaultArrayOfJSON: [JSON] = ["Oink", "Snuggles"]
            let pets = try testJSON.array("pet", or: defaultArrayOfJSON)
            XCTAssertEqual(pets, defaultArrayOfJSON, "`pets` should equal the `defaultArrayOfJSON`.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testArrayOfOr() {
        do {
            let matt = Resident(name: "Matt", age: 32, hasPet: false, rent: 500.00)
            let residentsOr = try json.arrayOf("residnts", or: [matt])
            XCTAssertEqual(residentsOr.first!, matt, "`residents` should not be nil")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testDictionaryOr() {
        do {
            let jsonDict: [String: JSON] = ["name": "Matt", "age": 33, "hasPet": false, "rent": .Null]
            let mattOr = try json.dictionary("residents", 4, or: jsonDict)
            XCTAssertEqual(jsonDict, mattOr, "`jsonDict` should equal `mattOr`")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testThatUnexpectedSubscriptIsThrown() {
        do {
            _ = try json.decode("residents", 1, "name", "initial", type: Resident.self)
        } catch JSON.Error.UnexpectedSubscript(let type) {
            XCTAssert(type == Swift.String, "The dictionary at index 1 should not be subscriptable by: \(type).")
        } catch {
            XCTFail("This should not be: \(error).")
        }
    }
    
    func testSubscriptIntoNullNotFound() {
        do {
            let nullJSON: JSON = .Null
            _ = try nullJSON.string("path", alongPath: .MissingKeyBecomesNil)
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
}

private struct Resident {
    let name: String
    let age: Int?
    let hasPet: Bool?
    let rent: Double?
}

extension Resident: JSONDecodable {
    private init(json: JSON) throws {
        name = try json.string("name")
        age = try json.int("age", alongPath: .MissingKeyBecomesNil)
        hasPet = try json.bool("hasPet", alongPath: .NullBecomesNil)
        rent = try json.double("rent", alongPath: [.NullBecomesNil, .MissingKeyBecomesNil])
    }
}

extension Resident: Equatable {}

private func ==(lhs: Resident, rhs: Resident) -> Bool {
    return (lhs.name == rhs.name) &&
    (lhs.age == rhs.age) &&
    (lhs.hasPet == rhs.hasPet) &&
    (lhs.rent == rhs.rent)
}