## Why Freddy?

Parsing JSON elegantly and safely can be hard, but Freddy is here to help. Freddy is a reusable framework for parsing JSON in Swift. It has three principal benefits.

First, Freddy provides a type safe solution to parsing JSON in Swift. This means that the compiler helps you work with sending and receiving JSON in a way that helps to prevent runtime crashes.

Second, Freddy provides an idiomatic solution to JSON parsing that takes advantage of Swift's generics, enumerations, and functional features. This is all provided without the pain of having to memorize our documentation to understand our magical custom operators. Freddy does not have any of those. If you feel comfortable writing Swift (using extensions, protocols, initializers, etc.), then you will not only understand how Freddy is organized, but you will also feel comfortable using Freddy.

Third, Freddy provides great error information for mistakes that commonly occur while parsing JSON.  If you subscript the JSON object with a key that is not present, you get an informative error.  If your desired index is out of bounds, you get an informative error.  If you try to convert a JSON value to the wrong type, you get a good error here too.

So, Freddy vs. JSON, who wins?  We think it is Freddy.

## Installation

You have three different options to install Freddy.

1. Add the project as a submodule
2. Use CocoaPods
3. Use Carthage

## Usage

This section describes Freddy's basic usage. You can find more examples on parsing data, dealing with errors, serializing `JSON` instances into `NSData`, and more in the [Wiki](https://github.com/bignerdranch/Freddy/wiki). 

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
Here is a quick example on how to parse this data using Freddy:

```swift
let data = getSomeData()
do {
    let json = try JSON(data: data) 
    let success = try json.bool("success")
    // do something with `success`
} catch {
    // do something with the error
}
```

After we load in the data, we create an instance of `JSON`, the workhorse of this framework. This allows us to access the values from the JSON data. We `try` because the `data` may be malformed and the parsing could generate an error. Next, we access the `"success"` key by calling the `bool(_:_:)` method on `JSON`. We `try` here as well because accessing the `json` for the key `"success"` could fail - e.g., if we had passed an unknown key. This method takes two parameters, both of which are used to define a path into the `JSON` instance to find a Boolean value of interest. If a `Bool` is found at the path described by `"success"`, then `bool(_:_:)` returns a `Bool`. If the path does not lead to a `Bool`, then an appropriate error is thrown.

With Freddy, it is possible to use a path to access elements deeper in the json structure. For example:

```swift
let data = getSomeData()
do {
    let json = try JSON(data: data)
    let georgiaZipCodes = try json.array("states","Georgia")
    let firstPersonName = try json.string("people",0,"name")
} catch {
    // do something with the error
}
```

There can be any number of subscripts and each subscript can be either a String indicating a named element in the json, or an Int that represents an element in an array. If there is something invalid in the path such as an index that doesn't exist in the json, an error will be thrown.

Now, let's look an example that parses the data into a model class:

```swift
let data = getSomeData()
do {
    let json = try JSON(data: data)
    let people = try json.array("people").map(Person.init) 
    // do something with `people`    
} catch {
    // do something with the error
}
```

Here, we are instead loading the values from the key `"people"` as an array using the method `array(_:_:)`. This method works a lot like the `bool(_:_:)` method you saw above. It uses the path provided to the method to find an array. If the path is good, the method will return an `Array` of `JSON`. If the path is bad, then an appropriate error is thrown.

We can then call `map` on that `JSON` array. Since the `Person` type conforms to `JSONDecodable`, we can pass in the `Person` type's initializer. This call applies an initializer that takes an instance of `JSON` to each element in the array, producing an array of `Person` instances.

Here is what `JSONDecodable` looks like:

```swift
public protocol JSONDecodable {
    init(json: JSON) throws
}
```

It is fairly simple protocol.  All it requires is that conforming types implement an initializer that takes an instance of `JSON` as its sole parameter.

To tie it all together, here is what the `Person` type looks like:

```swift
public struct Person {
    public let name: String
    public let age: Int
    public let spouse: Bool
}

extension Person: JSONDecodable {
    public init(json value: JSON) throws {
        name = try value.string("name")
        age = try value.int("age")
        spouse = try value.bool("spouse")
    } 
}
```

`Person` just has a few properties. It conforms to `JSONDecodable` via an extension. In the extension, we implement a `throws`ing initializer that takes an instance of `JSON` as its sole parameter. In the implementation, we `try` three functions: 1) `string(_:_:)`, 2) `int(_:_:)`, and 3) `bool(_:_:)`. Each of these works as you have seen before. The methods take in a path, which is used to find a value of a specific type within the `JSON` instance passed to the initializer. Since these paths could be bad, or the requested type may not match what is actually inside of the `JSON`, these methods may potentially throw an error. 

And that is pretty much it! Take a look at the framework's tests for further examples of usage.

