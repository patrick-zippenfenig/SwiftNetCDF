import XCTest
@testable import SwiftNetCDF

final class SwiftNetCDFTests: XCTestCase {
    /**
     Create a simple NetCDF file and write some data.
     Afterwards read the data again and check if it is the same.
     */
    func testCreateSimple() throws {
        let data = (Int32(0)..<50).map{$0}
        
        let file = try File.create(file: "test.nc", overwriteExisting: true, useNetCDF4: true)
        
        let dims = [
            try file.createDimension(name: "LAT", length: 10),
            try file.createDimension(name: "LON", length: 5)
        ]
        
        let vari = try file.createVariable(name: "MyData", type: Int32.self, dimensions: dims)
        try vari.write(data)
        file.sync()
        
        
        // Open the same file again and read the data
        let file2 = try File.open(file: "test.nc", allowWrite: false)
        let vari2 = try file2.getVariable(byName: "MyData")!.asType(Int32.self)!
        let data2 = try vari2.read()
        XCTAssertEqual(data, data2)
        
        
        // Compare the CDL notation of this file
        let cdl = """
group: / {
  dimensions:
        LAT = 10 ;
        LON = 5 ;
  variables:
        int32 MyData(LAT, LON) ;
  } // group /
"""
        XCTAssertEqual(cdl, try file2.getCdl())
    }
    
    func testAttributes() throws {
        let file = try File.create(file: "test.nc", overwriteExisting: true, useNetCDF4: true)
        try file.setAttribute("TEST1", Float(42))
        let attr1: Float = try file.getAttribute("TEST1")!.read()!
        XCTAssertEqual(attr1, 42)
        
        try file.setAttribute("TEST2", "42")
        let attr2: String = try file.getAttribute("TEST2")!.read()!
        XCTAssertEqual(attr2, "42")
        
        /*try file.setAttribute("TEST3", ["123","345"])
        let attr3: [String] = try file.getAttribute("TEST3")!.read()!
        XCTAssertEqual(attr3, ["123","345"])*/
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
        ("testAttributes", testAttributes),
        ("testExample", testExample),
    ]
}
