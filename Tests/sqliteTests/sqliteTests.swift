import XCTest
@testable import sqlite

final class sqliteTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(sqlite().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
