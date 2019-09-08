import XCTest
@testable import SwiftNetCDF

final class SwiftNetCDFTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftNetCDF().text, "Hello, World!")
        XCTAssertEqual(SwiftNetCDF().netCDFVersion, "4.6.1 of Apr 20 2018 10:09:42 $")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
