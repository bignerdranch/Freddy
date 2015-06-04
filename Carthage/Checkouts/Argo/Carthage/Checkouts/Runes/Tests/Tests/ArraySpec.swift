import Fox
import Nimble
import NimbleFox
import Quick
import Runes

private func generateArray(block:[String] -> Bool) -> FOXGenerator {
    return forAll(array(string())) { array in
        return block(array as! [String])
    }
}

class ArraySpec: QuickSpec {
    override func spec() {
        describe("Array") {
            describe("map") {
                // fmap id = id
                it("obeys the identity law") {
                    let property = generateArray() { array in
                        let lhs = id <^> array
                        let rhs = array

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // fmap (g . h) = (fmap g) . (fmap h)
                it("obeys the function composition law") {
                    let property = generateArray() { array in
                        let lhs = compose(append, prepend) <^> array
                        let rhs = compose(curry(<^>)(append), curry(<^>)(prepend))(array)

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }
            }

            describe("apply") {
                // pure id <*> v = v
                it("obeys the identity law") {
                    let property = generateArray() { array in
                        let lhs = pure(id) <*> array
                        let rhs = array

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // pure f <*> pure x = pure (f x)
                it("obeys the homomorphism law") {
                    let property = generateString() { string in
                        let lhs: [String] = pure(append) <*> pure(string)
                        let rhs: [String] = pure(append(string))

                        return rhs == lhs
                    }

                    expect(property).to(hold())
                }

                // u <*> pure y = pure ($ y) <*> u
                it("obeys the interchange law") {
                    let property = generateString() { string in
                        let lhs: [String] = pure(append) <*> pure(string)
                        let rhs: [String] = pure({ $0(string) }) <*> pure(append)

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // u <*> (v <*> w) = pure (.) <*> u <*> v <*> w
                it("obeys the composition law") {
                    let property = generateArray() { array in
                        let lhs = pure(append) <*> (pure(prepend) <*> array)
                        let rhs = pure(curry(compose)) <*> pure(append)  <*> pure(prepend) <*> array

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }
            }

            describe("flatMap") {
                // return x >>= f = f x
                it("obeys the left identity law") {
                    let property = generateString() { string in
                        let lhs: [String] = pure(string) >>- compose(append, pure)
                        let rhs: [String] = compose(append, pure)(string)

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // m >>= return = m
                it("obeys the right identity law") {
                    let property = generateArray() { array in
                        let lhs = array >>- pure
                        let rhs = array

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }

                // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
                it("obeys the associativity law") {
                    let property = generateArray() { array in
                        let lhs = (array >>- compose(append, pure)) >>- compose(prepend, pure)
                        let rhs = array >>- { x in compose(append, pure)(x) >>- compose(prepend, pure) }

                        return lhs == rhs
                    }

                    expect(property).to(hold())
                }
            }
        }
    }
}
