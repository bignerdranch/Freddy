import XCTest
@testable import FreddyTests

XCTMain([
     testCase(JSONDecodableTests.allTests),
     testCase(JSONEncodableTests.allTests),
     testCase(JSONEncodingDetectorTests.allTests),
     testCase(JSONOptionalTests.allTests),
     testCase(JSONParserTests.allTests),
//     testCase(JSONSerializingTests.allTests),
     testCase(JSONSubscriptingTests.allTests),
     testCase(JSONTests.allTests),
     testCase(JSONTypeTests.allTests),
])
