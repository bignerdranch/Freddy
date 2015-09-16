# BNRSwiftJSON
BNRSwiftJSON is a reusable framework for parsing JSON in Swift.

Its primary goal is faciliate the safe parsing of JSON, while also preserving the ease of use presented by parsing JSON in Objective-C.

## Instalation

- Add the project as a submodule
- Use CocoaPods
- Use Carthage

## Usage

Here is some example JSON data:

```json
{
    "success": true,
    "people": [
        {
            "name": "Matt Mathias",
            "age": 32,
            "spouse": true,
        },
        {
            "name": "Drew Mathias",
            "age": 33,
            "spouse": true,
        },
        {
            "name": "Sargeant Pepper",
            "age": 25,
            "spouse": false,
        }
    ],
    "jobs": [
        "teacher",
        "programmer",
        "judge"
    ],
    "states": {
        "Georgia": [
            30301,
            30302,
            30303
        ],
        "Wisconsin": [
            53000,
            53001,
            53002
        ]
    }
}
```

We wrote a quick method to load this JSON data locally for testing. This is where you would put your code to load your own JSON data.

```swift
func createData() -> NSData? {
    let testBundle = NSBundle(forClass: BNRSwiftJSONTests.self)
    let path = testBundle.pathForResource("sample", ofType: "JSON")

    if let p = path, u = NSURL(fileURLWithPath: p) {
        return NSData(contentsOfURL: u)
    }

    return nil
}
```

Now, here is a quick example on how to parse this data using BNRSwiftJSON:

```swift
let data = createData()
let json = JSON.createJSONFrom(data!)
let success = json["success"].bool
switch success {
case .Success(let s):
    println("Success!") // Do somethings with the value stored in 's'
case .Failure(let error):
    println(error) // Do something better with the error
}
```

After we load in the data, we create an instance of `JSON`, the workhorse of this framework. This allows us to access the values from the JSON data. Here, we access the `"success"` key, and also use computed properties to access the value as a bool. You can read more about these computer properties on the wiki [here](https://github.com/bignerdranch/bnr-swift-json/wiki/Computed-Properties). This returns a `Result` type that can be checked for `.Success` or `.Failure`.

Now, let's look an example that parses the data into a data class:

```swift
let data = createData()
let json = JSON.createJSONFrom(data!)
let peopleArray = json["people"].array
switch peopleArray {
case .Success(let people):
    for person in people {
        let per = Person.createWithJSON(person)
        switch per {
        case .Success(let p):
            println("Person Added!") // Do something with the created Person 'p'
        case .Failure(let error):
            println(error) // Do something better with the error
        }
    }
case .Failure(let error):
    println(error) // Do something better with the error
}
```

Here, we are instead loading the values from the key `"people"` as an array using the computed property. The biggest change here is passing the retrived `JSON` into the static method `Person.createWithJSON(person)` .

Here is our `Person` stuct:
```swift
public struct Person: JSONDecodable, Printable {
    public let name: String
    public let age: Int
    public let spouse: Bool

    public init(name: String, age: Int, spouse: Bool) {
        self.name = name
        self.age = age
        self.spouse = spouse
    }

    public static func createWithJSON(value: JSON) -> Result<Person> {
        let name = value["name"].string
        let age = value["age"].int
        let isMarried = value["spouse"].bool

        return name.flatMap { n in 
            age.flatMap { a in
                isMarried.map { im in 
                    return self.init(name: n, age: a, spouse: im)
                }
            }
        }
    }

    public var description: String {
        return "Name: \(name), age: \(age), married: \(spouse)"
    }
}
```

This struct makes use of the protocol `JSONDecodable` which implements the method `public static func createWithJSON(json: JSON) -> Result<Person>` . This creates a `Person` object from the given `JSON` by parsing the child values into variables. This also makes use of the computed type properties as well as the `map` and `flatMap` methods. You can read more about those methods in the [wiki](https://github.com/bignerdranch/bnr-swift-json/wiki/Methods-in-Result).

## Documentation

- [Wiki](https://github.com/bignerdranch/bnr-swift-json/wiki)

You can read more about the library in the wiki. You will find explanations for `JSON`, `JSONDecodable`, `map`, `flatMap`, the type computed properties, and more examples on how to best use BNRSwiftJSON.

## Conclusion

The primary goal of BNRSwiftJSON is to provide an elegant and safe solution to parsing JSON in Swift. A related, if not secondary, goal is to provide an idiomatic solution to JSON parsing. The solution we have provided involves a fair amount concepts borrowed from Functional Programming, a fact that isn't all that important to know.

Most important is to remember how to use the `JSONResult` and `Result` types provided by the framework. The role of these is to provide a safe way to encapsulate both `.Success` and `.Failure` in parsing JSON. The primary benefit is to ensure that parsing JSON reliably either provides the data that we are looking for, or an informative error should something not work as expected.

Last, it is important to note that while `flatMap` and `map` are not strictly required to use. If you prefer to use for loops and switch statements together, then feel free! You will still benefit from BNRSwiftJSON's safety and error handling. Nonetheless, `flatMap` and `map` can help your usage of BNRSwiftJSON to be more concise. They also follow the spirit of the framework, and make it easier to use once you master their complexity.