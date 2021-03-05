import XCTest
@testable import CZWebViewKit

final class CZWebViewKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CZWebViewKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
