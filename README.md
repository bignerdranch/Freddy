# Freddy

Freddy is a reusable framework for parsing JSON in Swift.

Its primary goal is facilitate the safe parsing of JSON, while also preserving the ease of use presented by parsing JSON in Objective-C.

## Installation

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
            "name": "Sargeant Pepper",
            "age": 25,
            "spouse": false,
        }
    ],
    "jobs": [
        "teacher",
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
            53001
        ]
    }
}
```

We wrote a quick method to load this JSON data locally for testing. This is where you would put your code to load your own JSON data.

```swift
func createData() -> NSData? {
    let testBundle = NSBundle(forClass: FreddyTests.self)
    let samplePath = testBundle.pathForResource("sample", ofType: "JSON")

    if let path = samplePath, url = NSURL(fileURLWithPath: path) {
        return NSData(contentsOfURL: url)
    }

    return nil
}
```

Now, here is a quick example on how to parse this data using Freddy:

```swift
let data = createData()
if let json = JSON.createJSONFrom(data) {
    let success = json["success"].bool
    switch success {
    case .Success(let s):
        println("Success!") // Do somethings with the value stored in 's'
    case .Failure(let error):
        println(error) // Do something better with the error
    }
}
```

After we load in the data, we create an instance of `JSON`, the workhorse of this framework. This allows us to access the values from the JSON data. Next, we access the `"success"` key, and also use a computed property to access the value as a `Bool`. This returns a `Result` type that can be checked for `.Success` or `.Failure`. You can read more about these computed properties on the wiki [here](https://github.com/bignerdranch/Freddy/wiki/Computed-Properties).

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

Here, we are instead loading the values from the key `"people"` as an array using the computed property `array`. The biggest change here is passing the retrieved `JSON` into the static method `Person.createWithJSON(person)` .

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

This struct makes use of the protocol `JSONDecodable` which implements the method `public static func createWithJSON(json: JSON) -> Result<Person>` . This creates a `Person` object from the given `JSON` by parsing the child values into variables. This also makes use of computed type properties as well as the `map` and `flatMap` methods. You can read more about those methods in the [wiki](https://github.com/bignerdranch/Freddy/wiki/Methods-in-Result).

## Documentation

- [Wiki](https://github.com/bignerdranch/Freddys/wiki)

You can read more about the library in the wiki. You will find explanations for `JSON`, `JSONDecodable`, `map`, `flatMap`, the type computed properties, and more examples on how to best use Freddy.

## Conclusion

Freddy provides an elegant and safe solution to parsing JSON in Swift. Secondarily, Freddy provides an idiomatic solution to JSON parsing.

To use Freddy successfully, first get familiar with the `JSONResult` and `Result` types provided by the framework. These provide a safe way to encapsulate both `.Success` and `.Failure` in parsing JSON, ensuring that parsing JSON reliably provides either the data that we are looking for, or an informative error should something not work as expected.

Last, it is important to note that usage of `flatMap` and `map` are not required. If you prefer to use for loops and switch statements together, then feel free! You will still benefit from Freddy's safety and error handling. Nonetheless, `flatMap` and `map` can help you have more concise parsing code. They also follow the spirit of the framework, and make it easier to use once you master the additional abstraction.
