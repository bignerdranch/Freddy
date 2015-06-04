import Fox

func id<A>(a: A) -> A {
    return a
}

func compose<A, B, C>(fa: A -> B, fb: B -> C) -> A -> C {
    return { x in fb(fa(x)) }
}

func curry<A, B, C>(f: (A, B) -> C) -> A -> B -> C {
    return { a in { b in f(a, b) }}
}

func append(x: String) -> String {
    return x + "bar"
}

func prepend(x: String) -> String {
    return "baz" + x
}

func generateString(block:String -> Bool) -> FOXGenerator {
    return forAll(string()) { string in
        return block(string as! String)
    }
}
