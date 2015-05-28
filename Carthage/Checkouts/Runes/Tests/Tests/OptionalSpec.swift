import Fox
import Nimble
import NimbleFox
import Quick
import Runes

private func generateOptional(block: String? -> Bool) -> FOXGenerator {
    return forAll(FOXOptional(string())) { optional in
        return block(optional as! String?)
    }
}

class OptionalSpec: QuickSpec {
    override func spec() {
        describe("Optional") {
            describe("map") {
                // fmap id = id
                it("obeys the identity law") {
                    let property = generateOptional() { optional in
                        let lhs = id <^> optional
                        let rhs = optional

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // fmap (g . h) = (fmap g) . (fmap h)
                it("obeys the function composition law") {
                    let property = generateOptional() { optional in
                        let lhs = compose(append, prepend) <^> optional
                        let rhs = compose(curry(<^>)(append), curry(<^>)(prepend))(optional)

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }
            }

            describe("apply") {
                // pure id <*> v = v
                it("obeys the identity law") {
                    let property = generateOptional() { optional in
                        let lhs = pure(id) <*> optional
                        let rhs = optional

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // pure f <*> pure x = pure (f x)
                it("obeys the homomorphism law") {
                    let property = generateString() { string in
                        let lhs: String? = pure(append) <*> pure(string)
                        let rhs: String? = pure(append(string))

                        return rhs == lhs
                    }

                    expect(property).to(hold())
                }

                // u <*> pure y = pure ($ y) <*> u
                it("obeys the interchange law") {
                    let property = generateString() { string in
                        let lhs: String? = pure(append) <*> pure(string)
                        let rhs: String? = pure({ $0(string) }) <*> pure(append)

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // u <*> (v <*> w) = pure (.) <*> u <*> v <*> w
                it("obeys the composition law") {
                    let property = generateOptional() { optional in
                        let lhs = pure(append) <*> (pure(prepend) <*> optional)
                        let rhs = pure(curry(compose)) <*> pure(append)  <*> pure(prepend) <*> optional

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }
            }

            describe("flatMap") {
                // return x >>= f = f x
                it("obeys the left identity law") {
                    let property = generateString() { string in
                        let lhs: String? = pure(string) >>- compose(append, pure)
                        let rhs: String? = compose(append, pure)(string)

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // m >>= return = m
                it("obeys the right identity law") {
                    let property = generateOptional() { optional in
                        let lhs = optional >>- pure
                        let rhs = optional

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
                it("obeys the associativity law") {
                    let property = generateOptional() { optional in
                        let lhs = (optional >>- compose(append, pure)) >>- compose(prepend, pure)
                        let rhs = optional >>- { x in compose(append, pure)(x) >>- compose(prepend, pure) }

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }
            }
        }
    }
}
