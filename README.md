## Why Freddy?

Freddy is a reusable framework for parsing JSON in Swift. It has three principal benefits.

First, Freddy provides a type safe solution to parsing JSON in Swift. This means that the compiler help you work with sending and receiving JSON in a way that helps to prevent runtime crashes.

Second, Freddy provides an idiomatic solution to JSON parsing that takes advantage of Swift's generics, enumerations, and functional features. 

Third, Freddy provides a mechanism for handling errors that commonly occur while parsing JSON.  If you subscript the JSON object with a key that is not present, you get an informative error.  If your desired index is out of bounds, you get an informative error.  If you try to convert a JSON value to the wrong type, you get a good error here too.

Parsing JSON elegantly and safely can be hard, but Freddy is here to help.  So, Freddy vs. JSON, who wins?  We think it is Freddy.

## Installation

You have three different options to install Freddy.

1. Add the project as a submodule
2. Use CocoaPods
3. Use Carthage

## Usage

This section describes some of the basics in using Freddy.  Check out the wiki for more information, as well as some discussion on how Freddy works.

Consider some example JSON data:

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
            "name": "Sergeant Pepper",
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
Here is a quick example on how to parse these data using Freddy:

```swift
let data = getSomeData()
if let json = JSON.createJSONFrom(data) {
    let success = json["success"].bool
    switch success {
    case .Success(let s):
        print("Success!") // Do something with the value stored in 's'
    case .Failure(let error):
        print(error) // Do something better with the error
    }
}
```

After we load in the data, we create an instance of `JSON`, the workhorse of this framework. This allows us to access the values from the JSON data. Next, we access the `"success"` key, and also use a computed property to access the value as a `Bool`. This returns a `Result` type that can be checked for `.Success` or `.Failure`. You can read more about these computed properties on the wiki [here](https://github.com/bignerdranch/Freddy/wiki/Computed-Properties).

Now, let's look an example that parses the data into a model class:

```swift
let data = getSomeData()
let json = JSON.createJSONFrom(data)
let peopleArray = json["people"].array
switch peopleArray {
case .Success(let people):
    for person in people {
        let per = Person.createWithJSON(person)
        switch per {
        case .Success(let p):
            print("Person Added!") // Do something with the created Person 'p'
        case .Failure(let error):
            print(error) // Do something better with the error
        }
    }
case .Failure(let error):
    print(error) // Do something better with the error
}
```

Here, we are instead loading the values from the key `"people"` as an array using the computed property `array`. The biggest change here is passing the retrieved `JSON` into the static method `Person.createWithJSON(person)` .

Here is our `Person` stuct:
```swift
public struct Person: JSONDecodable, CustomStringConvertible {
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

This struct conforms to the protocol `JSONDecodable`, which requires conforming types to implement the public `static` method `createWithJSON(_:) -> Result<T>` . This creates a `Person` instance from the given `JSON`. The example also makes use of computed type properties as well as the `map` and `flatMap` methods. You can read more about those methods in the [wiki](https://github.com/bignerdranch/Freddy/wiki/Methods-in-Result).

Take a look at the framework's tests for further examples of usage.

## Documentation

- [Wiki](https://github.com/bignerdranch/Freddys/wiki)

You can read more about the library in the wiki. You will find explanations for `JSON`, `JSONDecodable`, `map`, `flatMap`, the type computed properties, and more examples on how to best use Freddy.

