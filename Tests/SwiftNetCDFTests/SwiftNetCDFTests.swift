import XCTest
@testable import SwiftNetCDF

final class SwiftNetCDFTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftNetCDF().text, "Hello, World!")
        //XCTAssertEqual(SwiftNetCDF().netCDFVersion, "4.6.3 of May  8 2019 00:09:03 $")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
