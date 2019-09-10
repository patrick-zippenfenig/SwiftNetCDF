import XCTest
@testable import SwiftNetCDF

final class SwiftNetCDFTests: XCTestCase {
    /**
     Create a simple NetCDF file and write some data.
     Afterwards read the data again and check if it is the same.
     */
    func testCreateSimple() throws {
        let file = try File.create(file: "test.nc", overwriteExisting: true, useNetCDF4: true)
        
        let dims = [
            try file.createDimension(name: "LAT", length: 10),
            try file.createDimension(name: "LON", length: 5)
        ]
        
        let vari = try file.createVariable(name: "MyData", type: Int32.self, dimensions: dims)
        
        let data = (Int32(0)..<50).map{$0}
        try vari.write(data)
        file.sync()
        
        // Open the same file again and read the data
        let file2 = try File.open(file: "test.nc", allowWrite: false)
        let vari2 = try file2.getVariable(byName: "MyData")!.asType(Int32.self)!
        
        let data2 = try vari2.read()
        XCTAssertEqual(data, data2)
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftNetCDF().text, "Hello, World!")
        //XCTAssertEqual(SwiftNetCDF().netCDFVersion, "4.6.3 of May  8 2019 00:09:03 $")
    }

    static var allTests = [
        ("testCreateSimple", testCreateSimple),
        ("testExample", testExample),
    ]
}
