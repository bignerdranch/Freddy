## Parsing JSON in Swift

BNRSwiftJSON is a reusable framework for parsing JSON in Swift.
Its primary goal is faciliate the safe parsing of JSON, while also preserving the ease of use presented by parsing JSON in Objective-C.

## Usage

Here are several examples of parsing JSON.
Many of these examples can also be reviewed in the framework's test target: `BNRSwiftJSONTests`.

# Loading Data

The process begins with loading the JSON data.
Our example uses the following JSON:

```
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

For convenience, we model the loading of JSON from a file located in the framework's target for tests.

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

The function `createData()` creates an optional instance of `NSData` containing the JSON above.
In a real app, this function would be replaced by whatever yields the JSON payload, most likely some call to a web service.

# The Motivation

Typically, we would do something like this in Swift to get the JSON data:

```swift
if let data = createData() {
    var error: NSError?
    let stuff = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? [String: AnyObject]
	       
    var persons: [Person] = []
    if let people = stuff?["people"] as? [[String: AnyObject]] {
        for person in people {
	    if let name = person["name"] as? String, age = person["age"] as? Int, spouse = person["spouse"] as? Bool {
	        persons.append(Person(name: name, age: age, spouse: spouse))
            }
        }
    }
}
```

Swift 1.2 added an improvement to Optional Binding that allows for multiple bindings in a single `if-let`.
This feature lowers the summit of the above pyramid of doom, but there is still significant nesting.

Furthermore, the above code is difficult to debug.
If any of the above optional bindings fail for some reason, then the result is `nil` and we do not have any data.
We ideally would like the syntax to be clean, while also being able to check informative errors should any arise.

# Using BNRSwiftJSON

`BNRSwiftJSON` is a framework that provides clean syntax, safe typing, and useful information in parsing JSON.
Errors are tracked, stored, and are available to use after parsing.
Consider the above example using `BNRSwiftJSON`.

```swift
let data = createData()
let json = JSONValue.createJSONValueFrom(data!)
let peopleArray = json["people"].array
switch peopleArray {
case .Success(let people):
	for person in people {
		let per = Person.createWithJSONValue(person)
		switch per {
		case .Success(let p):
			someContainer.append(p)
		case .Failure(let error):
			println(error) // do something better with the error
		}
	}
case .Failure(let error):
	println(error) // do something better with the error
}
```

The above example demonstrates the safety and ease-of-use that the comes with using `BNRSwiftJSON`. 
`JSONValue` is an enumeration with cases matching each value of JSON that may be returned by a web service.
The method `createWithJSONValueFrom(_:)` takes an instance of `NSData` and returns an instance of `JSONValueResult`.
This type has two cases: `.Success` that will have an associated value of type `JSONValue`, and `.Failure` with an associated value of type `NSError`.
Thus, it will quite apparent of there is or is not JSON data to parse.
Moreover, if there is an error parsing the JSON, then the `.Failure` case will carry with it the associated error information.

Once you have a `JSONValueResult`, you can use various subscriptors and computed properties to get the data.
The code in the above example uses the key `people` to extract the array of persons returned by the web service.
The `array` computed property on `JSONValueResult` returns an instance of the `Result` type, which is similar to `JSONValueResult`.
`Result` has two cases, one for a generic value in the `.Success` case, and another `.Failure` case for error information.
If there is data available for `array` to pull out of the `JSONValueResult` instance, then it will return `Result<[JSONValue]>`.
This return type can be interpreted as a `Result` with potentially an array of `JSONValue`s inside of its `.Success` case.

Next, `peopleArray` is `switch`ed over to determine if there is data.
In the `.Success` case, you can grab the array of `JSONValue`s: `case .Success(let people):`.
This line of code places the array of `JSONValue`s in a constant called `people`.
You can then loop through these `JSONValue`s create instances of some model.

The example above uses a `Person` struct.
Here is its implementation:

```swift
public struct Person: JSONValueDecodable, Printable {
	public let name: String
	public let age: Int
	public let spouse: Bool

	public init(name: String, age: Int, spouse: Bool) {
		self.name = name
		self.age = age
		self.spouse = spouse
	}

	public static func createWithJSONValue(value: JSONValue) -> Result<Person> {
		let name = value["name"].string
		let age = value["age"].int
		let isMarried = value["spouse"].bool

		return name.bind { n in 
			age.bind { a in
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

Notice that the `Person` struct conforms to a protocol: `JSONValueDecodable`.
The protocol requires an implementation of a `static` method to construct an instance of the model: `createWithJSONValue(_:)`.
This method takes an instance of `JSONValue`, which is used to extract the model's relevant data.

Finally, notice that `createWithJSONValue(_:)` returns a `Result` with a `Person` in its `.Success` case's associated value if everything goes well.
The benefit here is that you will know if `createWithJSONValue(_:)` succeeds in making an instance.
If the method does not succeed, then you will know why by checking the associated value in the `.Failure` case.

Do not be concerned with the implementation of `createWithJSONValue(_:)` at this point.
Understanding this method entails an explanation of `bind` and `map`, which we will get to below.
For now, it is more important to understand the basic mechanics: you create an instance of your model object with a `JSONValue`, and you return a `Result` from `createWithJSONValue(_:)`.

# A More Elegant Way

The above example is very safe, but is perhaps a little mechanical.
The `for` loop and nested `switch` statements are not ideal.
There is a more elegant way to accomplish the same task.

```swift
let data = createData()
let json = JSONValue.createJSONValueFrom(data!)

let peopleArray = json.bind({ $0["people"] }).array.bind { collectResults(map($0, Person.createWithJSONValue)) }
var people = [Person]()
switch peopleArray {
case .Success(let box):
	box.value.map { people.append($0) } 
case .Failure(let error):
	println(error) // do something better with the error
}
```

The above example is considerably more complex, and dense, than the previous implementation.
Nonetheless, it accomplishes the same task in a much more compact manner.
In order to understand how `peopleArray` is created and what it holds, you will have to have a feeling for how `Result`, `bind`, and `map` work.

These are the topics of the next sectionn.

## Underlying Machinery

The method `createJSONValueFromData(_:)` returns  a `JSONValueResult` containing the resulting `JSONValue` in its `.Success` case.
Let's take a look at `JSONValue` before moving on.

```swift 
public enum JSONValue {
    case JSONArray([JSONValue])
    case JSONDictionary([String: JSONValue])
    case JSONNumber(Double)
    case JSONString(String)
    case JSONBool(Bool)
    case JSONNull

    ...
}
```

A `JSONValue` is an enumeration with cases that match the sort of data modeled by JSON.
Most of the cases for this enum all have associated values, with `JSONNull` being the exception.
`JSONArray` and `JSONDictionary` have associated values that refer back to the `JSONValue` enumeration itself.
For example, the associated value for `JSONArray` can hold an array of `JSONDictionary`, where each dictionary will hold `String` keys and `JSONValue` values.
As you can imagine, the method `createJSONValueFrom(_:)` will create an instance of the `JSONValue` enum recursively.

Here is the implementation of `createJSONValueFrom(_:)`.

```swift
public static func createJSONValueFrom(data: NSData) -> JSONValueResult {
    let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)

    if let obj: AnyObject = jsonObject {
        return .Success(makeJSONValue(obj)
    } else {
        let errorDictionary = [NSLocalizedFailureReasonErrorKey: "Could not parse `NSData`."
        let error = NSError(domain: "com.bignerdranch.BNRSwiftJSON", code: JSONValue.BNRSwiftJSONErrorCode.CouldNotParseJSON.rawValue, userInfo: errorDictionary)
	return .Failure(error)
    }
}
```

The method above helps take an instance of `NSData` and returns an instance of `JSONValueResult`.
`JSONValueResult` is an enum that has two cases: `.Success` and `.Failure`.
The `.Success` case has an associated value of type `JSONValue`.
The `.Failure` case has an associated value of type `NSError`.
Thus, when `createJSONValueFrom(_:)` completes, it will either return the data you are looking for, or it will return a helpful error describing what went wrong.

If the data provided to `createJSONValueFrom(_:)` can be made into a JSON object, then this object is given to the `makeJSONValue(_:)` method on `JSONValue`.
The result of this method is returned as the associated value of the `.Success` case above.
As you may be able to infer, `makeJSONValue(_:)` returns an instance of `JSONValue`.

Instances of `JSONValue` are made recursively.
That is, `makeJSONValue(_:)` will traverse the object yielded by `JSONObjectWithData(_: options: error:)` and create `JSONValue` instances by calling itself.
Here is how it is implemented.

```swift
private static func makeJSONValue(object: AnyObject) -> JSONValue {
    switch object {
    case let arr as [AnyObject]:
        return makeJSONValueArray(arr)
    case let dict as [String: AnyObject]:
        return makeJSONValueDictionary(dict)
    case let n as Double:
        return .JSONNumber(n)
    case let s as String:
        return .JSONString(s)
    case let b as Bool:
        return .JSONBool(b)
    default:
        return JSONNull
    }
}
```

This method with `switch` over the `object` (of type `AnyObject`) given to it.
If a case is matched, then it will return case of `JSONValue` with its corresponding associated value.
For example, if `object` is a `Bool`, then this value is associated with a `.JSONBool`.

The cases for matching on arrays and dictionaries are a bit more complicated.
Let's begin with arrays.

If the `object` passed into `makeJSONValue(_:)` is an array, then this case will match: `case let arr as [AnyObject]:`.
This line of code binds an array of `AnyObject` to  a constant called `arr`.
The constant, `arr`, is then passed to `makeJSONValueArray(_:)`.

At this point, the task is to transform `arr`, which is a `[AnyObject]`, into a `[JSONValue]`.
In words, `arr` needs to be changed from an array of `AnyObject`s into an array of `JSONValue`s.
The method `makeJSONValueArray(_:)` is designed to do just this task.

```swift
private static func makeJSONValueArray(jsonArray: [AnyObject]) -> JSONValue {
    var items = [JSONValue]()
    for item in jsonArray {
        let value = makeJSONValue(item)
	items.append(value)
    }
    return .JSONArray(items)
}
```

The above method takes an `[AnyObject]` and returns a `JSONValue`.
In this case, we know that the returned object will be a `.JSONArray` with an associated value of `[JSONValue]`.
How will we accomplish this conversion?

The first step in the implementation is to create an empty array of type `[JSONValue]`.
We will append `JSONValue`s to this array as they are made.
Next, we iterate through `jsonArray` to convert each `item` into a `JSONValue`.
To do so, we pass `item` to `makeJSONValue(_:)`.
As we have seen above, `makeJSONValue(_:)` will create an instance of `JSONValue`.
We append the result to our array of `JSONValue`s, and return after we have looped through all of the items in `jsonArray`.

The implementation for creating dictionaries is very similar.
If the `object` passed to `makeJSONValue(_:)` matches the type `[String: AnyObject]`, then we pass the object to `makeJSONValueDictionary(_:)`.
This function takes dictionaries of type `[String: AnyObject]`, and converts them into dictionaries of type `[String: JSONValue]`.
These are the dictionaries that will be associated with the `.JSONDictionary` case.

```swift
private static func makeJSONValueDictionary(jsonDict: [String: AnyObject]) -> JSONValue {
    var dict = [String: JSONValue]()
    for (key, value) in jsonDict {
        dict[key as String] = makeJSONValue(value)
    }
    return .JSONDictionary(dict)
}
```

Making dictionaries of `JSONValue`s works very similarly to making arrays of `JSValues`.
We begin by making an empty dictionary with the correct type: `[String: JSONValue]`.
Next, we iterate through the `jsonDict` given to the `makeJSONValueDictionary(_:)` method.
We gave each `value` that we found to `makeJSONValue(_:)` to make an instance of `JSONValue`, and associated this value with its corresponding `key`.
After we iterate through all of the items in `jsonDict`, we return a `.JSONDictionary` with the dictionary of `JSONValue`s as its associated value.

At this point, every value in `object` that was given to `makeJSONValue(_:)` has been converted to a `JSONValue`.
This method recursively traversed the data described by `object`, calling itself along the way.
The result will be a `JSONValue` instance whose structure will match the JSON payload delivered by a web service, with one key difference: the instance of `JSONValue` will pack the JSON's data into associated values of `JSONValue` within each matching case.
The next trick to discuss is how data can be safely, and conveniently, retried from the `JSONValue` enum.

# Subscripting `JSONValue`

# Computed Properties on `JSONValue`

