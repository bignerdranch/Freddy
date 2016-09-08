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
    
    private var residentJSON: JSON!
    private var json: JSON!
    private var noWhiteSpaceData: NSData!
    
    func parser() -> JSONParserType.Type {
        return JSONParser.self
    }
    
    override func setUp() {
        super.setUp()
        
        residentJSON = JSON.Dictionary([
            "residents": [
                ["name": "Matt", "age": 33, "hasPet": false, "rent": .Null],
                ["name": "Drew", "hasPet": true, "rent": 1234.5],
                ["name": "Pat", "age": 28, "hasPet": .Null]
            ],
            "residentsByName": [
                "Matt": ["name": "Matt", "age": 33, "hasPet": false, "rent": .Null],
                "Drew": ["name": "Drew", "hasPet": true, "rent": 1234.5],
                "Pat": ["name": "Pat", "age": 28, "hasPet": .Null]
            ]
            ])
        
        let testBundle = NSBundle(forClass: JSONSubscriptingTests.self)
        guard let data = testBundle.URLForResource("sample", withExtension: "JSON").flatMap(NSData.init) else {
            XCTFail("Could not read sample data from test bundle")
            return
        }
        
        do {
            self.json = try JSON(data: data, usingParser: parser())
        } catch {
            XCTFail("Could not parse sample JSON: \(error)")
            return
        }
        
        guard let noWhiteSpaceData = testBundle.URLForResource("sampleNoWhiteSpace", withExtension: "JSON").flatMap(NSData.init) else {
            XCTFail("Could not read sample data (no whitespace) from test bundle")
            return
        }
        
        self.noWhiteSpaceData = noWhiteSpaceData
    }
    
    func testThatArrayOfProducesResidents() {
        do {
            let residents = try residentJSON.arrayOf("residents", type: Resident.self)
            let residentsNames = residents.map { $0.name }
            XCTAssertEqual(residentsNames.count, 3, "There should be 3 residents.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testThatDictionaryOfProducesResidentsByName() {
        do {
            let residentsByName = try residentJSON.dictionaryOf("residentsByName", type: Resident.self)
            let residentsNames = residentsByName.map { $1.name }
            XCTAssertEqual(residentsNames.count, 3, "There should be 3 residents.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsDecodes() {
        do {
            let firstResident = try residentJSON.decode("residents", 0, alongPath: [.NullBecomesNil, .MissingKeyBecomesNil], type: Resident.self)
            XCTAssertNotNil(firstResident)
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsProducesOptionalForNotFoundWithArrayOf() {
        do {
            let residents = try residentJSON.arrayOf("residents", type: Resident.self)
            XCTAssertNil(residents[1].age, "Drew's `age` should be nil.")
        } catch {
            XCTFail("There should be no error.")
        }
    }
    
    func testNullOptionsProducesOptionalForNotFoundWithDictionaryOf() {
        do {
            let residents = try residentJSON.dictionaryOf("residentsByName", type: Resident.self)
            XCTAssertNotNil(residents["Drew"])
            XCTAssertNil(residents["Drew"]?.age, "Drew's `age` should be nil.")
        } catch {
            XCTFail("There should be no error.")
        }
    }
    
    func testNullOptionsProducesOptionalForNullOrNotFoundWithArrayOf() {
        do {
            let residents = try residentJSON.arrayOf("residents", type: Resident.self)
            XCTAssertNil(residents.first?.rent, "Matt should have nil `rent`.")
            XCTAssertEqual(residents[1].rent!, 1234.5, "Drew's `rent` should equal 1234.5.")
            XCTAssertNil(residents.last?.rent, "Pat should have nil `rent`.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsProducesOptionalForNullOrNotFoundWithDictionaryOf() {
        do {
            let residents = try residentJSON.dictionaryOf("residentsByName", type: Resident.self)
            XCTAssertNotNil(residents["Matt"])
            XCTAssertNil(residents["Matt"]?.rent, "Matt should have nil `rent`.")
            XCTAssertEqual(residents["Drew"]!.rent!, 1234.5, "Drew's `rent` should equal 1234.5.")
            XCTAssertNotNil(residents["Pat"])
            XCTAssertNil(residents["Pat"]?.rent, "Pat should have nil `rent`.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testNullOptionsIndexOutOfBoundsProducesOptional() {
        do {
            let residentOutOfBounds = try residentJSON.decode("residents", 4, alongPath: .MissingKeyBecomesNil, type: Resident.self)
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
    
    func testDictionaryOfJSONIntAndNullCreatesOptionalWhenDetectNull() {
        let testJSON: JSON = ["one": 1, "two": 2, "three": .Null, "four": 4]
        do {
            _ = try testJSON.dictionaryOf(alongPath: .NullBecomesNil, type: Int.self)
            XCTFail("`testJSON.dictionaryOf(_:options:type:)` should throw.")
        } catch let JSON.Error.ValueNotConvertible(value, type) {
            XCTAssert(type == Int.self, "value (\(value)) is not equal to \(type).")
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
    
    func testDecodeNullBecomesNilProducesOptional() {
        let json: JSON = ["type": "Apartment", "resident": .Null]
        do {
            let apartment = try json.decode(alongPath: .NullBecomesNil, type: Apartment.self)
            XCTAssertNil(apartment?.resident, "This resident should be nil!")
        } catch {
            XCTFail("There should be no error: \(error)")
        }
    }
    
    func testJSONDictionaryUnexpectedSubscript() {
        do {
            _ = try residentJSON.decode(1, type: Resident.self)
            XCTFail("Should throw error.")
        } catch JSON.Error.UnexpectedSubscript(type: let theType) {
            XCTAssertTrue(theType is Int.Type)
        } catch {
            XCTFail("Didn't catch the right error: \(error).")
        }
    }
    
    func testJSONIndexSubscript() {
        let residents = residentJSON["residents"]
        XCTAssertNotNil(residents)
    }
    
    func testJSONKeySubscript() {
        let matt = residentJSON["residents"]?[0]
        XCTAssertNotNil(matt)
    }
    
    func testDecodeOr() {
        do {
            let outOfBounds = try residentJSON.decode("residents", 4, or: Resident(name: "NA", age: 30, hasPet: false, rent: 0))
            XCTAssertTrue(outOfBounds.name == "NA")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testDoubleOr() {
        do {
            let rent = try residentJSON.double("residents", 2, "rent", or: 0)
            XCTAssertTrue(rent == 0, "Rent should be free.")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testStringOr() {
        do {
            let nickname = try residentJSON.string("residents", 0, "nickname", or: "DubbaDubs")
            XCTAssertTrue(nickname == "DubbaDubs")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testIntOr() {
        do {
            let age = try residentJSON.int("residents", 1, "age", or: 21)
            XCTAssertTrue(age == 21, "Forever young!")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testBoolOr() {
        do {
            let hasSpouse = try residentJSON.bool("residents", 1, "hasSpouse", or: false)
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
            let residentsOr = try residentJSON.arrayOf("residnts", or: [matt])
            XCTAssertEqual(residentsOr.first!, matt, "`residents` should not be nil")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testDictionaryOr() {
        do {
            let jsonDict: [String: JSON] = ["name": "Matt", "age": 33, "hasPet": false, "rent": .Null]
            let mattOr = try residentJSON.dictionary("residents", 4, or: jsonDict)
            XCTAssertEqual(jsonDict, mattOr, "`jsonDict` should equal `mattOr`")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testDictionaryOfOr() {
        do {
            let matt = Resident(name: "Matt", age: 32, hasPet: false, rent: 500.00)
            let residentsOr = try residentJSON.dictionaryOf("residnts", or: ["Matt": matt])
            XCTAssertEqual(residentsOr, ["Matt": matt], "`residents` should not be nil")
        } catch {
            XCTFail("There should be no error: \(error).")
        }
    }
    
    func testThatUnexpectedSubscriptIsThrown() {
        do {
            _ = try residentJSON.decode("residents", 1, "name", "initial", type: Resident.self)
        } catch JSON.Error.UnexpectedSubscript(let type) {
            XCTAssert(type == Swift.String, "The dictionary at index 1 should not be subscriptable by: \(type).")
        } catch {
            XCTFail("This should not be: \(error).")
        }
    }
    
    func testMissingKeyOptionStillFailsIfNullEncountered() {
        do {
            let json = JSON.Dictionary([
                "name": "Drew",
                "age": nil, // should cause problems!
                "hasPet": true,
                "rent": 1234.5,
                ])
            let resident = try Resident(json: json)
            XCTFail("Unexpected success: \(resident)")
        } catch let JSON.Error.ValueNotConvertible(value: value, to: type) {
            XCTAssert(type == Int.self, "unexpected type \(type) of value \(value)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSubscriptingOptionsStillFailIfKeyIsMissing() {
        do {
            let json = JSON.Dictionary([
                "name": "Drew",
                "rent": 1234.5,
                ])
            let resident = try Resident(json: json)
            XCTFail("Unexpected success: \(resident)")
        } catch let JSON.Error.KeyNotFound(key: key) where key == "hasPet" {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testThatMapCanCreateArrayOfPeople() {
        let peopleJSON = try! json.array("people")
        let people = try! peopleJSON.map(Person.init)
        for person in people {
            XCTAssertNotEqual(person.name, "", "There should be a name.")
        }
    }
    
    func testThatSubscriptingJSONWorksForTopLevelObject() {
        let success = try? json.bool("success")
        XCTAssertEqual(success, true, "There should be `success`.")
    }
    
    func testThatPathSubscriptingPerformsNesting() {
        for z in try! json.array("states", "Georgia") {
            XCTAssertNotNil(try? z.int(), "The `Int` should not be `nil`.")
        }
    }
    
    func testJSONSubscriptWithInt() {
        let mattmatt = try? json.string("people", 0, "name")
        XCTAssertEqual(mattmatt, "Matt Mathias", "`matt` should hold string `Matt Mathias`")
    }
    
    func testJSONErrorKeyNotFound() {
        do {
            _ = try json.array("peopl")
        } catch JSON.Error.KeyNotFound(let key) {
            XCTAssert(key == "peopl", "The error should be due to the key not being found.")
        } catch {
            XCTFail("The error should be due to the key not being found, but was: \(error).")
        }
    }
    
    func testJSONErrorIndexOutOfBounds() {
        do {
            _ = try json.dictionary("people", 4)
        } catch JSON.Error.IndexOutOfBounds(let index) {
            XCTAssert(index == 4, "The error should be due to the index being out of bounds.")
        } catch {
            XCTFail("The error should be due to the index being out of bounds, but was: \(error).")
        }
    }
    
    func testJSONErrorTypeNotConvertible() {
        do {
            _ = try json.int("people", 0, "name")
        } catch let JSON.Error.ValueNotConvertible(value, to) {
            XCTAssert(to == Swift.Int, "The error should be due the value not being an `Int` case, but was \(to).")
            XCTAssert(value == "Matt Mathias", "The error should be due the value being the String 'Matt Mathias', but was \(value).")
        } catch {
            XCTFail("The error should be due to `name` not being convertible to `int`, but was: \(error).")
        }
    }
    
    func testJSONErrorUnexpectedSubscript() {
        do {
            _ = try json.string("people", "name")
        } catch JSON.Error.UnexpectedSubscript(let type) {
            XCTAssert(type == Swift.String, "The error should be due the value not being subscriptable with string `String` case, but was \(type).")
        } catch {
            XCTFail("The error should be due to the `people` `Array` not being subscriptable with `String`s, but was: \(error).")
        }
    }
    
    func testThatOptionalSubscriptingIntoNullSucceeds() {
        let earlyNull = [ "foo": nil ] as JSON
        let string = try! earlyNull.string("foo", "bar", "baz", alongPath: .NullBecomesNil)
        XCTAssertNil(string)
    }
    
    func testThatOptionalSubscriptingKeyNotFoundSucceeds() {
        let keyNotFound = [ "foo": 2 ] as JSON
        let string = try! keyNotFound.string("bar", alongPath: .MissingKeyBecomesNil)
        XCTAssertNil(string)
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

private struct Apartment {
    let type: String
    let resident: Resident?
}

extension Apartment: JSONDecodable {
    private init(json: JSON) throws {
        type = try json.string("type")
        resident = try json.decode("resident", alongPath: .NullBecomesNil, type: Resident.self)
    }
}

extension Resident: Equatable {}

private func ==(lhs: Resident, rhs: Resident) -> Bool {
    return (lhs.name == rhs.name) &&
    (lhs.age == rhs.age) &&
    (lhs.hasPet == rhs.hasPet) &&
    (lhs.rent == rhs.rent)
}

class JSONSubscriptWithNSJSONTests: JSONSubscriptingTests {
    
    override func parser() -> JSONParserType.Type {
        return NSJSONSerialization.self
    }
    
}

// Just for syntax validation, not for execution or being counted for coverage.
private func testUsage() {
    let j = JSON.Null
    
    _ = try? j.int()
    _ = try? j.int(alongPath: .MissingKeyBecomesNil)
    _ = try? j.int(alongPath: .NullBecomesNil)
    _ = try? j.int(or: 42)
    
    _ = try? j.int("key")
    _ = try? j.int("key", alongPath: .MissingKeyBecomesNil)
    _ = try? j.int("key", alongPath: .NullBecomesNil)
    _ = try? j.int("key", or: 42)
    
    _ = try? j.int(1)
    _ = try? j.int(2, alongPath: .MissingKeyBecomesNil)
    _ = try? j.int(3, alongPath: .NullBecomesNil)
    _ = try? j.int(4, or: 42)
    
    let stringConst = "key"
    
    _ = try? j.int(stringConst, 1)
    _ = try? j.int(stringConst, 2, alongPath: .MissingKeyBecomesNil)
    _ = try? j.int(stringConst, 3, alongPath: .NullBecomesNil)
    _ = try? j.int(stringConst, 4, or: 42)
}
