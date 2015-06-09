## Parsing JSON in Swift

Freddy is a reusable framework for parsing JSON in Swift.
Its primary goal is faciliate the safe parsing of JSON, while also preserving the ease of use presented by parsing JSON in Objective-C.

## Usage

Here are several examples of parsing JSON.
Many of these examples can also be reviewed in the framework's test target: `FreddyTests`.

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
            "name": "Sergeant Pepper",
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
	let testBundle = NSBundle(forClass: FreddyTests.self)
	let path = testBundle.pathForResource("sample", ofType: "JSON")

	if let p = path, u = NSURL(fileURLWithPath: p) {
		return NSData(contentsOfURL: u)
	}
	        
	return nil
}
```

The function `createData()` creates an optional instance of `NSData` containing the JSON above.
In a real app, this function would be replaced by whatever yields the JSON payload, most likely some call to a web service.

### Quick Examples

Imagine that we want to see if the `"success"` key is `true`.

```swift
let data = createData()
let json = JSONValue.createJSONValueFrom(data!)
let success = json["success"].bool
switch success {
case .Success(let s):
    println("Success!")
case .Failure(let error):
    println(error) // Do something better with the error
}
```

We first use `createData()` to simulate downloading data.
Next, we create an instance of `JSONValue`, the workhorse of this framework, and place it in the constant `json`.
We can subscript (i.e., `["success"]`) and use computed properties (i.e., `bool`) on `json` to access the value of interest.
Doing so will either give the data to `success` or an error.
We cover these details in greater depth below, but suffice it to say now that `success` is an enum with one of either two cases: `.Success` or `.Failure`.

We can also use Freddy to access nested keys.
Consider the following code to get access the `"name"` of the first person in the `"people"` array.

```swift
let data = createData()
let json = JSONValue.createJSONValueFrom(data!)
let matt = json["people"][0]["name"].string
switch matt {
case .Success(let n):
    println(n.value) // "Matt Mathias"
case .Failure(let error):
    println(error) // Do something better with the error
}
```

The key `"people"` accesses the array in the JSON for people, and `0` accesses the first index.
This first index corresponds to a dictionary, and so we can subscript that by the `"name"` key.
Last, we use the computed property `string` to get this key's `String` representation, and give it to a constant `matt`.
At that point, we can `switch` over `matt` to determine if we were successful.

The next section describes how we would typically JSON data to create instances of model objects.
It then proposes Freddy as a safer solution, and moves on to illustrate how it can be used.

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

## Using Freddy

`Freddy` is a framework that provides clean syntax, safe typing, and useful information in parsing JSON.
Errors are tracked, stored, and are available to use after parsing.
Consider the above example of parsing JSON reworked to use `Freddy`.

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

`Freddy` provides safety and ease-of-use. 
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
        let error = NSError(domain: "com.bignerdranch.Freddy", code: JSONValue.FreddyErrorCode.CouldNotParseJSON.rawValue, userInfo: errorDictionary)
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

### Subscripting 

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
                    return .Failure(makeError(FreddyErrorCode.KeyNotFound, problem: key))
                }
            default:
                return .Failure(makeError(FreddyErrorCode.UnexpectedType, problem: key))
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
                    return .Failure(makeError(FreddyErrorCode.IndexOutOfBounds, problem: index))
                }
            default:
	            return .Failure(makeError(FreddyErrorCode.UnexpectedType, problem: index))
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

### Computed Properties

Recall the following line of code from the first example of using `Freddy`.

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
                return .Failure(jsonValue.makeError(JSONValue.FreddyErrorCode.TypeNotConvertible, problem: "Array"))
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

Here is the implementation of `Result`.

```swift
public enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)

	...

}
```

The `Result` enum is declared with something called a *placeholder type*: `public enum Result<T> {`.
This first line declares a generic placeholder type `T` that will defined when the `Result` enum is used.
Placeholders such as `T` above allow types to be highly resusable.

These placeholders can even be referred to within the definition of the generic type.
For example, notice that `T` is used in the `.Success` case's associated value: `case Success(Box<T>)`.
What is `Box<T>`?

Recall that in the previous section we lamented that the Swift compiler cannot accommodate enumerations with generic cases.
We mentioned that there is a trick that allows us to get around this limitation.
`Box` is the trick.
Here is how it is implemented.

```swift
public final class Box<T> {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}
```

`Box` is a `public` and `final` class.
That means it can visible outside of this module, and it cannot be subclassed.
Like `Result`, it declares a generic placeholder, and refers to it inside of its implmentation.
`Box` has a single `public` property that is a constant called `value`, and it is of type `T`.
This type also has a single initializer that takes one argument: the `value` to be given to its property.

So, while Swift's enumerations cannot yet (we say *yet* because we assume it will some day) handle generic cases, we know that Swift enums can have associated values.
We also know that an enum's associated values can be any type.
Furthermore, we know that Swift allows us to declare generic types.
Therefore, it stands to reason that we can create a generic type and list it as our `Result` enum's associated value.

`Box` is a utility type that will only be used in coordination with the `Result` enum.
It acts as a `box` to put values inside and ship around with a `Result` as needed.

Let's look into how `Box` is used with the `Result` type.

### Using `Box`

Recall the `array` computed property on `JSONValueResult`.

```swift
public extension JSONValueResult {
    var array: Result<[JSONValue]> {
        return bind { jsonValue in
            if let array = jsonValue.array {
                return .Success(Box(array))
            } else {
                return .Failure(jsonValue.makeError(JSONValue.FreddyErrorCode.TypeNotConvertible, problem: "Array"))
            }
        }
    }
	...
}
```

Notice the first `return` if `jsonValue.array` is able to yield an unwrapped `[JSONValue]`: `return .Success(Box(array))`.
This line creates an instance of `Box`, places the `array` in `Box`'s `value` property, and associates the `Box` instance with `JSONValueResult`'s `.Success` case.
Put more informally, the code creates a value of interest, places it in a box for safekeeping, and the ships it with the return value of computed property.

The next step is to retrieve a value from a `Box`.
Recall the above example that creates instances of the `Person` type from the sample JSON.

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

The example creates creates instances of the `Person` type and appends them to `someContainer`.
This work is done in the `for` loop.
For every `person` that is found in `peopleArray`, we create an instance of `Person` with the method `createWithJSONValue(_:)`.
This method returns a `Result<Person>`; that is, an instance of `Result` with a `Person` instance inside of the `Box` associated with its `.Success` case.

That means we need to `switch` on the return from `createWithJSONValue(_:)`.

```swift
let per = Person.createWithJSONValue(person)
switch per {
case .Success(let p):
    someContainer.append(p)
case .Failure(let error):
    println(error) // do something better with the error
}
```

If we find success, then we append the `Box` with the `Person` inside of it to our array.
Using these data can be done like so:

```swift
if let firstPerson = someContainer.first {
    println(firstPerson.value.name) // Logs person's name to console
}
```

Remember that we were appending instances of `Box<Person>` to our array called `someContainer`.
That means we need to do two things to get the person out of the box.
First, if we need to need to get the first person in the array, then we use the computed property `first` on the array.
This property returns an optional, and so we need to unwrap it, which we do so via optional binding.

Second, we can access the person instance via the `value` property on the `Box` instance.
For example, that means we can ask the `value` for the person's name.

## `JSONValueDecodable`

We mentioned before that `Freddy` provides a protocol to help model objects create instances from `JSONValue`s.
It is time to take a look at the protocol.

```swift
public protocol JSONValueDecodable {
    static func createWithJSONValue(value: JSONValue) -> Result<Self>
}
```

`JSONValueDecodable` provides a type level method called `createWithJSONValu(_:)`.
This mentod takes an instance of `JSONValue`, and returns a `Result` with an instance of `Self` in its `.Success` case.
A conforming type implements this method to use a `JSONValue` to create an instance of itself.

Let's take a look at how the `Person` type conforms to `JSONValueDecodable`.

```swift
extension Person: JSONValueDecodable {
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
}
```

`Person` conforms to `JSONValueDecodable` in an extension.
Notice that the implementation `Person` provides returns a `Result<Person>`.
This return means that creating a `Person` will yield a `Result` with either an instance of `Person` or an informative error if a problem should occur.

The implementation of `createWithJSONValue(_:)` begins by making use of subscripting on `JSONValue`, and the uses computed properties on the resulting `JSONValueResult`.
(Remember: that subscripting `JSONValue` returns a `JSONValueResult`.)
The computed properties on `JSONValueResult` return a `Result<T>`.

```swift
let name = value["name"].string
let age = value["age"].int
let isMarried = value["spouse"].bool
```

For example, `name` is a `Result<String>`; that is, `name` is a `Result` with a `Box` holding a `String` in its `.Success` case.

After using relevant computed properties on all of the values that are needed to create an instance of the model type, we then need to figure out how to get the values out of the `Result`s.
In order to do so, we need to introduce two new methods on `Result<T>`: `bind` and `map`.
The next section describes these methods and closes the discussion of how to use `createWithJSONValue(_:)`.

### More Methods on `Result<T>`

To create an instance of the `Person` type, we need to conform to a protocol called `JSONValueDecodable` and implement its sole required method.

```swift
extension Person: JSONValueDecodable {
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
}
```

The above section discussed how to use subscripting and computed properties on the `JSONValue` to get the necessary data to create an instance.
An important question remains: how do we use those values?
All of the data pulled from `JSONValue` in `createWithJSONValue(_:)` are some form of `Result`.
We need a way to pull the data from these results, and a convenient way to chain these data into a call to the `Person` type's initializer.
Enter `bind` and `map`.

The `Result<T>` type needs to define two new methods to facilitate the creation of instances of a given model type.

### `bind`

You have seen `bind` defined and used already on `JSONValueResult`.
The generic `Result<T>` also defines `bind`.
Whereas `JSONValueResult` was explicit about the parameters in the function provided to its sole argument in `bind`, `Result<T>` will define `bind` more generically.

```swift
public enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)
    
    public func bind<U>(f: T -> Result<U>) -> Result<U> {
        switch self {
        case let .Failure(error):
            return .Failure(error)
        case let .Success(value):
            return f(value.value)
        }
    }
}
```

As with the other definitions of `bind` that you have seen, this version takes a function and uses it to produce a `Result`.
The function type of `bind` on `Result` looks like this: `(T -> Result<U>) -> Result<U>`.
In words, `bind` takes a function with a generic parameter `T` and returns a `Result` with a generic parameter `U`.
This `Result<U>` is the return value of `bind`.

The benefit of `bind` taking a generic parameter in the function and returning a generic `Result` means that you can use it with virtually any value of interest.
This flexibility allowed us to use `bind` on a `Result` with a `String`, `Int`, or `Bool` inside of the `Box` in the `.Success` case.
It is up to the function given to `bind` to determine how the value in question is slotted within a `Result`.

Consider again the code from `createWithJSONValue(_:)` that created the `Person` instance.

```swift
...
return name.bind { n in
    age.bind { a in
        isMarried.map { im in
            return self.init(name: n, age: a, spouse: im)
        }
    }
}
...
```

Remember that `name`, `age`, and `isMarried` are values that were created previously.
The goal of this code is to 'unbox' the values from the `Result` instances represented by `name`, `age`, and `isMarried`.
We use `bind` to 'unbox' those values and nest another call to `bind` to make sure that we have access to all of the values required by the initializer on the `Person` type.

For example, `name.bind { n in ` grabs the `String` representing a person's name from the JSON that we have been working with, and places it within `n`.
Since this call to `bind` uses a closure, that means `n` is available within this scope.
This case is true for `age` (i.e., `a`) and `isMarried` (i.e., `im`) as well.

The last wrinkle to discuss is that final call to `map`.
Why are we using `map` instead of `bind` here?

### `map`

In the above example, we used `bind` to chain the values from various `Result` instances together to create an instance of the `Person` type.
We finished off the chain with a call to `map` when we reached the final property the `Person` type's initializer expected: `isMarried`.
It is worthwhile to mention here that the order is not important; we could have ended with a call to `map` on `age` or `name` if we so chose.
The point to emphasize is that the final value needs to have `map` called on it.
Why?

Recall that `bind` takes a `T` and returns a `Result<U>`.
This function type allows you to chain multiple calls to `bind` together.
In our case, we nest calls to `bind` in order to 'unbox' the values needed for the intializer we want to use to create a `Person` instance.

When we finally get to `isMarried`, we need to do two things.
First, we need to 'unbox' the `Bool` value inside of the `Result`.
Second, we need to pass all of the values we just 'unboxed' and pass them to the memberwise initializer on `Person`.
Notice, however, that this initializer returns a `Person`.
This reality will not meet the requirement established by the function type for `createWithJSONValue(_:)`, which needs to return a `Result<Person>`.

Thus, the challenge before us is to figure out how we can wrap up the `Person` instance returned by the memberwise initializer within a `Result`.
It turns out that we can use `map` on the `Result` type to help us with this task.
We can define `map` as follows:

```swift
public enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)

    public func map<U>(f: T -> U) -> Result<U> {
        switch self {
        case let .Failure(error):
            return .Failure(error)
        case let .Success(value):
            return .Success(Box(f(value.value)))
        }
    }
	...
}
```

In distinction to `bind`, our implementation of `map` wraps up the supplied value in a `Box` instance and places that within the `.Success` case of the `Result` type.
While `bind` relies upon the supplied function to do the work of putting the value of interest within a `Result`, `map` does this work for us.
That means `map` is the perfect solution for us to use with the initializer on the `Person` type.

```swift
isMarried.map { im in
    return self.init(name: n, age: a, spouse: im)
}
```

The above code uses a closure to 'unbox' the `Bool` value from `isMarried` and places it within a local constant `im`.
At this point, all of the values required by the `Person` type's memberwise initializer are available to use.
We can therefore call the initilizer and return the instance within `map`, whose implementation will place the `Person` instance within a `Box` inside of the `Result` type's `.Success` case.
Notice that this operation satisfies the return type of `createWithJSONValue(_:)`, which is `Result<Person>`.

## A More Elegant Way

Now that you understand how `Result`, `bind`, and `map` work, you are ready to see and use a more compact solution for parsing JSON.
While the first example we provided of working with `JSONValue` was safe and explicit, it is perhaps a little mechanical.
The `for` loop and nested `switch` statements are not ideal.

We can use `bind` and `map` to help us accomplish the same task in a more elegant fashion.

```swift
let data = createData()
let json = JSONValue.createJSONValueFrom(data!)
let peopleArray = json.bind { $0["people"] }.array.bind { collectResults(map($0, Person.createWithJSONValue)) }
var people = [Person]()
switch peopleArray {
case .Success(let box):
	box.value.map { people.append($0) } 
case .Failure(let error):
	println(error) // do something better with the error
}
```

The above example is somewhat more complex than our previous example.
Nonetheless, it accomplishes the same task in a much more compact manner.
Moreover, it makes good use of the `bind` and `map`, which helps to make our code more elegant at no cost to its expressiveness.

In fact, there is only one really complicated line of code above:

```swift
let peopleArray = json.bind { $0["people"] }.array.bind { collectResults(map($0, Person.createWithJSONValue)) }
```

Let's break this line down piece by piece.

We start out with `json`, which is an instance of `JSONValueResult` returned by `createJSONValueFrom(_:)`.
Since `json` is a `JSONValueResult`, we can use the version of `bind` we defined on that type.
Recall that we defined two versions of `bind` on `JSONValueResult`.
In this case, we will use the version with the following function type: `(JSONValue -> JSONValueResult) -> JSONValueResult`.
Using this version means that we can access `JSONValueResult`'s subscripts and computed properties.

Inside of `bind`'s closure, we have access to the `JSONValue` held within the `.Success` case of `JSONValueResult`.
`$0` will be that instance of `JSONValue`, which means that we can subscript it with `$0["people"]`.
This subscript will return the array of people encapsulated by the JSON inside of a `JSONValueResult`.
The return value satisfies what this version of `bind` is expecting, a `JSONValueResult`.

Next, we used the `array` computed property on `JSONValueResult`.
This use of `array` takes the `JSONValueResult` and places the `JSONValue` in its `.Success` case inside of a `Result` whose type will be: `Result<[JSONValue]>`.
In other words, you used the `array` computed property to grab the array of `JSONValue`s that you know the `people` key corresponds to inside of the JSON.

Since you now have a `Result`, with `[JSONValue]` inside of it, you can use the generic version of `bind` defined on the `Result` type.
Doing so will expose the array of `JSONValue`s holding the people data inside of it that we are interested in using.
The question is: how can we use these data?

The trick is to remember that the generic version of `bind` expects to return a `Result<U>`.
This expectation means that we will need to return a `Result`.
Ideally, we would like to return a `Result` with an array of people in its `.Success` case: `Result<[Person]>`.
There are a number of other useful forms these data can take.
We can define a `collectResults(_:)` function inside of `Result.swift` to facilitate this process.


### `collectResults(_:)`

At this point, we are stuck at the call to the generic `bind` defined on `Result`.
Inside of this closure, we used a new function that we have not yet discussed: `collectResults(_:)`.
This function takes one argument of type `[Result<T>]` and returns a `Result<[T]>`.
In other words, it takes an array of `Result`s of a generic type, and returns a single `Result` where the instances have been appended to an array in the `.Success` case.

```swift
public func collectResults<T>(results: [Result<T>]) -> Result<[T]> {
    var successes = [T]()
    for result in results {
        switch result {
        case .Success(let res):
            successes.append(res.value)
        case .Failure(let error):
            return .Failure(error)
        }
    }
    return .Success(Box(successes))
}
```

The implementation of `collectResults(_:)` is fairly straightforward.
We create an empty array of type `T`.
Next, we iterate over the `Result`s provided to the `results` argument.
We `switch` over each `Result`, checking for `.Success` and `.Failure`.
If we encounter a `.Success`, we append the `value` of that `Result` to the empty `successes` array.
If we find a `.Failure`, then we pass the error through to the `.Failure` case to the `Result`.
Finally, if we found no error, then we return `.Success(Box(successes))`; or, we place the `successes` array inside of a `Box` and give that instance to the `.Success` case of `Result`.

Now we need to figure out how to give `collectResults(_:)` a value that its argument expects: `[Result<T>]`.
Thankfully, we do not need to write a custom function or method to handle this work.
Instead, we can make use of the global function `map` provided by the standard library.
This version of `map` will take a `CollectionType` as its argument, and will iterate over the collection applying a supplied function to each element.
Remember that the standard library's definition of `map` returns an array of type `[T]`.  

It turns out that this type is exactly what we want.
The function `collectResults(_:)` expects an array of `Results`.
Therefore, we can use this version of `map` to iterate over the array of `JSONValue`s that will be exposed to `bind`.
We ask `map` to apply the method `createWithJSONValue(_:)` defined on the `Person` type to each element in the array `[JSONValue]`.
The return value of `map` is then an array of `Person` `Result`s: `[Result<Person>]`.
We can give this array to `collectResults(_:)` to convert the array `[Result<Person>]` to `Result<[Person]>`
Note that this conversion meets the expectation of `bind` that it returns a `Result`.

After all of this work, the type of `peopleArray` is a `Result` with an array of `Person` in its `.Success` case: `Result<[Person]>`.
We can then `switch` on `peopleArray` to do whatever we like with the `Person` instances.
If we find `.Success`, then we can append these model instances to an array.
If we find `.Failure`, then we can handle that case as needed because the error will contain useful information describing why the operation failed.

## Conclusion

The primary goal of Freddy is to provide an elegant and safe solution to parsing JSON in Swift.
A related, if not secondary, goal is to provide an idiomatic solution to JSON parsing.
The solution we have provided involves a fair amount concepts borrowed from Functional Programming, a fact that isn't all that important to know.

Most important is to remember how to use the `JSONValueResult` and `Result` types provided by the framework.
The role of these is to provide a safe way to encapsulate both `.Success` and `.Failure` in parsing JSON.
The primary benefit is to ensure that parsing JSON reliably either provides the data that we are looking for, or an informative error should something not work as expected.

Last, it is important to note that while `bind` and `map` are not strictly required to use.
If you prefer to use `for` loops and `switch` statements together, then feel free!
You will still benefit from Freddy's safety and error handling.
Nonetheless, `bind` and `map` can help your usage of `Freddy` to be more concise.
They also follow the spirit of the framework, and make it easier to use once you master their complexity.