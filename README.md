## Parsing JSON in Swift

BNRSwiftJSON is a reusable framework for parsing JSON in Swift.
Its primary goal is faciliate the safe parsing of JSON, while also preserving the ease of use presented by parsing JSON in Objective-C.

## Usage

Here are several examples of parsing JSON.
Many of these examples can also be reviewed in the framework's test target: `BNRSwiftJSONTests`.

### Loading Data

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

## The Motivation

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

## Using BNRSwiftJSON

`BNRSwiftJSON` is a framework that provides clean syntax, safe typing, and useful information in parsing JSON.
Errors are tracked, stored, and are available to use after parsing.
Consider the above example of parsing JSON reworked to use `BNRSwiftJSON`.

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

`BNRSwiftJSON` provides safety and ease-of-use. 
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
The next trick to discuss is how data can be safely, and conveniently, retrieved from the `JSONValue` enum.

### Subscripting `JSONValue` and `JSONValueResult`

Recall that `createJSONValueFrom(_:)` returns a `JSONValueResult`.
That means the code above that subscripts `json` like so: `json["people"]` is actually subscripting an instance of `JSONValueResult`.
Indeed, the more elegant code that we just reviewed that uses `bind` and `map` was actually working on an instance of `JSONValueResult`.

Let's first take a look at `JSONValueResult`.

```swift
public enum JSONValueResult {
	case Success(JSONValue)
        case Failure(NSError)

	...
}
```

`JSONValueResult` is an enumeration with two cases: `Success` and `Failure`.
The `Success` case has an associated value of type `JSONValue`, and the `Failure` case has an associated value of type `NSError`.
Thus, an instance of `JSONValueResult` can either hold a valid `JSONValue` or an instance of `NSError` explaining what went wrong.

As mentioned above, `JSONValueResult` provides subscripts to facilitate the parsing of JSON data.

```swift
public extension JSONValueResult {
	subscript(key: String) -> JSONValueResult {
        return bind { jsonValue in 
            return jsonValue[key]
        }
    }

	subscript(index: Int) -> JSONValueResult {
        return bind { jsonValue in
            return jsonValue[index]
        }
    }
}
```

`JSONValueResult` defines two subscripts.
The first takes an argument, `key`, of type `String`, and returns a `JSONValueResult`.
This subscript allows for the subscripting of a `JSONValueResult` similar to a `Dictionary`.
The second subscript takes an argument `index` of type `Int`, and operates similarly to subscripting an `Array`.

Both subscripts use `bind` and apply the subscript to something labeled as `jsonValue`.
What is `jsonValue`?
We will take a look at this question first, and will return to how `bind` works afterward.

The subscripts for `JSONValueResult` actually apply a given subscript to an instance of `JSONValue`.
In other words, `JSONValue` itself defines these two subscripts as well.

```swift
public extension JSONValue {
    subscript(key: String) -> JSONValueResult {
        get {
            switch self {
            case .JSONDictionary(let jsonDict):
                if let obj = jsonDict[key] {
                    return .Success(obj)
                } else {
                    return .Failure(makeError(BNRSwiftJSONErrorCode.KeyNotFound, problem: key))
                }
            default:
                return .Failure(makeError(BNRSwiftJSONErrorCode.UnexpectedType, problem: key))
            }
        }
    }

    subscript(index: Int) -> JSONValueResult {
        get {
            switch self {
            case .JSONArray(let jsonArray):
                if index <= jsonArray.count - 1 {
                    return .Success(jsonArray[index])
                } else {
                    return .Failure(makeError(BNRSwiftJSONErrorCode.IndexOutOfBounds, problem: index))
                }
            default:
	            return .Failure(makeError(BNRSwiftJSONErrorCode.UnexpectedType, problem: index))
	        }
        }
    }
}
```

The subscripts on `JSONValue` return instances of `JSONValueResult`.
Each subscript `switch`es over `self`, which in this case will be an instance of `JSONValue`.
If `self` matches the expected case on `JSONValue` (e.g., the subscript for an array should match the case `.JSONArray`.), then we apply the subscript to the bound value in the matching case.
For example, if the supplied `index` is within the range of the existing `jsonArray`, then an instance of `JSONValueResult`'s `.Success` case is returned with the `index` applied to `jsonArray` as its associated value.
If the supplied `index` is out of bounds, or if `self` does not match the expected case, then an appropriate error is created and returned as the associated value of the `.Failure` case of `JSONValueResult`.

Putting it all together now, we see that the subscript on `JSONValueResult` returns the result of applying the subscript to an instance of `JSONValue`.
The subscript on `JSONValue` actually returns an instance of `JSONValueResult`.
Let undiscussed at this point is how the function `bind` helps these subscripts to work.
That is the topic of the next section.

### `bind`

Now that we understand how the subscripts work on `JSONValueResult` and `JSONValue`, we can discuss the role of `bind`.
This method is defined on `JSONValueResult`.

```swift 
enum JSONValueResult {
    ...
    public func bind(f: JSONValue -> JSONValueResult) -> JSONValueResult {
        switch self {
        case .Failure(let error)
            return .Failure(error)
	    case .Success(let jsonValue):
	        return f(jsonValue)
	    }
    }
    ...
}
```

The goal of `bind` is to provide a way to place a `JSONValue` within an instance of `JSONValueResult`.
Hence the name `bind`: if successful, the method *binds* an instance of `JSONValue` to the `.Success` case of `JSONValueResult`.
If not successful, `bind` will pass through the existing `error` to the `JSONValueResult`.
Let's take a closure look at this method.

The function type of `bind` is: `(JSONValue -> JSONValueResult) -> JSONValueResult`.
In words, `bind` takes an argument that is a function itself that expects a `JSONValue` as its argument and returns a `JSONValueResult`, while `bind` returns a `JSONValueResult`.
Thus, `bind` needs to be given an appropriate function in order to return what it needs to.

Returning to the implementation of subscript on `JSONValueResult` helps to elucidate how `bind` works.

```swift 
public extension JSONValueResult {
    subscript(key: String) -> JSONValueResult {
        return bind { jsonValue in
            return jsonValue[key]
	    }
    }
    ...
}
```

In the above subscript, `bind` is used to place an instance of `JSONValue` into a `JSONValueResult`.
Recall that `bind`'s argument takes a function and returns a `JSONValueResult`.
That function takes a `JSONValue` as its argument and itself returns a `JSONValueResult`.
The above code uses `bind` to subscript `jsonValue` with the given `key`.
Subscripting in this manner satisfies the contract established by `bind`'s argument because `jsonValue[key]` will return a `JSONValueResult`.

### Computed Properties on `JSONValue`

Recall the following line of code from the first example of using `BNRSwiftJSON`.

```swift
let data = createData()
let json = JSONValue.createJSONValueFrom(data!)
let peopleArray = json["people"].array
...
```

Notice that not only do we apply a subscript to `json`, but we also access a computed property called `array` on the `JSONValueResult` yielded by the subscript `people`.
You can probably guess that this `array` property returns an array of some sort, but what exactly is inside of this array, and how is it made?
The answers to these questions are the topic of this section.

The goal of the computed properties on `JSONValueResult` is to find the associated value in the `JSONValueResult`'s `.Success` case and create a type that matches the requested computed property.
In this example above, we are trying to grab the key `people` from the JSON, and get its corresponding array.
Let's take a look at the implementation of the `array` property on `JSONValueResult` to see what is going on.

```swift
public extension JSONValueResult {
    var array: Result<[JSONValue]> {
        return bind { jsonValue in
            if let array = jsonValue.array {
                return .Success(Box(array))
            } else {
                return .Failure(jsonValue.makeError(JSONValue.BNRSwiftJSONErrorCode.TypeNotConvertible, problem: "Array"))
            }
        }
    }
	...
```

All of the computed properties on `JSONValueResult` are defined within this same extension.
For simplicity, we only discuss the `array` computed property, but the others work very similarly (e.g., `dictionary`, `string`, `bool`, etc.)

The `array` property finds the appropriate array in the `JSONValue` and returns that array in the `.Success` case of a new `Result` type.
Notice that this computed property uses a `bind` method in a manner similar to what we have seen before.
This version of `bind` is a bit different, and we will get to exactly how its different in just a moment.

Focus instead on what is going on inside of this new version of `bind`.
There is something called `jsonValue`, which is an instance of `JSONValue`, just as before.
This `JSONValue` is used by accessing its version of the `array` computed property.

```swift
public extension JSONValue {
    var array: [JSONValue]? {
        switch self {
        case .JSONArray(let value):
            return value
        default:
            return nil
        }
    }
}
```

`JSONValue`'s computed property `array` `switch`es over `self` to ensure that the matching case is `.JSONArray`.
If this case matches, then the associated value is bound to a local constant called `value` and is returned.
If this case does not match, then we return `nil` to indicate that we did not find that anticipated data.
Thus, `JSONValue`'s `array` property returns an optional array of `JSONValue`s: `[JSONValue]?`.

Returning back to the implementation of `array` on `JSONValueResult`, you should notice that the computed property does not return an optional on this type.
Instead, if `jsonValue.array` does not succeed and returns `nil`, we then return `.Failure` with an appropriately constructed error detailing the mistake.
If `jsonValue.array` does succeed, then we bind that value to `array` and return it as the associated value of `.Success`.

Notice that the return type of `array` on `JSONValueResult` is `Result<[JSONValue]>`?
This result type is a bit different than `JSONValueResult`, though it is very similar in spirit.
It seeks to succinctly model either success or failure.
An instance of `Result` will either carry with it data, or an informative error describing what went wrong.
Before we go into the details of `Result`, let's take a look at what this new `bind` method does.

```swift
public enum JSONValueResult {
    case Success(JSONValue)
    case Failure(NSError)

    public func bind(f: JSONValue -> JSONValueResult) -> JSONValueResult {
        switch self {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let jsonValue):
            return f(jsonValue)
        }
    }
   
    public func bind<T>(f: JSONValue -> Result<T>) -> Result<T> {
        switch self {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let jsonValue):
            return f(jsonValue)
        }
    }
}
```

We have included the version of `bind` that we covered previously for the sake of comparison.
This new version of `bind` has a few distinguishing features.
First, it is a generic function: it specifies a generic parameter `T`.
This parameter is used to specify the type that we anticipate using with the `Result` in this method.

Second, though this version of `bind` also takes a function, its type is a bit different than what we have seen before.
The new `bind` method has the following type: `(JSONValue -> Result<T>) -> Result<T>`.
It takes a function as its sole argument, and returns an instance of `Result`.
The function `bind` takes in its argument itself takes `JSONValue` as its argument and returns a `Result<T>`.
As before, this version of `bind` relies upon the function supplied to its argument to produce its return value.

Thus, the `array` property on `JSONValueResult` asks a `JSONValue` for a `[JSONValue]?`.
If there is one of these, the value is unwrapped from the optional, and is bound to the `.Success` case of a `Result` instance.
Otherwise, there was an error, and we bind that to the `.Failure` case of a `Result`.

At this point, you might be asking yourself some questions. 
"Why do we need another version of `Result`?"
"Just what is a `Result<T>`?"
"And what is that weird `Box` type I saw in the `array` property on `JSONValueResult`?"

The answers to these questions are the subject of the next section.

### `Result<T>`

`Result` is a generic enumeration, with a twist.
Swift does not yet support a enumeration with generic cases.
We have to resort to a trick to get the Swift compiler to cooperate.

**Describe what <T> means**
**Describe why <T> is needed**
**Describe why we need Box**

### `map`

## `JSONValueDecodable` and `createWithJSONValue(_:)`

## A More Elegant Way

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

These are the topics of the next section.

### `collectResults(_:)`, `splitResults(_:)`, and `splitResult(_: f:)`

## Conclusion

