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
    
    /**
     Write and read all attribute data-types
     */
    func testAttributes() throws {
        let data_float = [Float(42), 34, 123]
        let file_raw = try File.create(file: "test.nc", overwriteExisting: true, useNetCDF4: true)
        let variable = try file_raw.createGroup(name: "TEST").createVariable(name: "TEST_VAR", type: Int32.self, dimensions: [try file_raw.createDimension(name: "MYDIM", length: 5)])
        let file = variable.variable
        
        try file.setAttribute("TEST_FLOAT", data_float)
        XCTAssertEqual(try file.getAttribute("TEST_FLOAT")!.read(), data_float)
        
        let data_float_nan = [Float.nan, Float.infinity, Float.signalingNaN]
        try file.setAttribute("TEST_FLOAT_NAN", data_float_nan)
        let data_nan = try file.getAttribute("TEST_FLOAT_NAN")!.read()! as [Float]
        XCTAssertTrue(data_nan[0].isNaN)
        XCTAssertTrue(data_nan[1].isInfinite)
        XCTAssertTrue(data_nan[2].isSignalingNaN)
        
        let data_double = [123.2,127.23,-127.32]
        try file.setAttribute("TEST_DOUBLE", data_double)
        XCTAssertEqual(try file.getAttribute("TEST_DOUBLE")!.read(), data_double)
        
        let data_string = ["123","345","678"]
        try file.setAttribute("TEST_STRING", data_string)
        XCTAssertEqual(try file.getAttribute("TEST_STRING")!.read(), data_string)
        XCTAssertEqual(file.numberOfAttributes, 4)
        
        
        // Signed integers
        let data_int8 = [Int8(123),127,-127]
        try file.setAttribute("TEST_INT8", data_int8)
        XCTAssertEqual(try file.getAttribute("TEST_INT8")!.read(), data_int8)
        
        let data_int16 = [Int16(1263),1627,.min,.max]
        try file.setAttribute("TEST_INT16", data_int16)
        XCTAssertEqual(try file.getAttribute("TEST_INT16")!.read(), data_int16)
        
        let data_int32 = [Int32(12653),16627,-12767,.min,.max]
        try file.setAttribute("TEST_INT32", data_int32)
        XCTAssertEqual(try file.getAttribute("TEST_INT32")!.read(), data_int32)
        
        let data_int64 = [Int64(12653),16627,-12767,.min,.max]
        try file.setAttribute("TEST_INT64", data_int64)
        XCTAssertEqual(try file.getAttribute("TEST_INT64")!.read(), data_int64)
        
        let data_int = [123,345,-678,.min,.max]
        try file.setAttribute("TEST_INT", data_int)
        XCTAssertEqual(try file.getAttribute("TEST_INT")!.read(), data_int)
        XCTAssertEqual(file.numberOfAttributes, 9)
        

        // Unsigned integers
        let data_uint8 = [UInt8(123),127,.min,.max]
        try file.setAttribute("TEST_UINT8", data_uint8)
        XCTAssertEqual(try file.getAttribute("TEST_UINT8")!.read(), data_uint8)
        
        let data_uint16 = [UInt16(1263),1627,.min,.max]
        try file.setAttribute("TEST_UINT16", data_uint16)
        XCTAssertEqual(try file.getAttribute("TEST_UINT16")!.read(), data_uint16)
        
        let data_uint32 = [UInt32(12653),16627,.min,.max]
        try file.setAttribute("TEST_UINT32", data_uint32)
        XCTAssertEqual(try file.getAttribute("TEST_UINT32")!.read(), data_uint32)
        
        let data_uint64 = [UInt64(123),345,678,.min,.max]
        try file.setAttribute("TEST_UINT64", data_uint64)
        XCTAssertEqual(try file.getAttribute("TEST_UINT64")!.read(), data_uint64)
        
        let data_uint = [UInt(123),345,678,.min,.max]
        try file.setAttribute("TEST_UINT", data_uint)
        XCTAssertEqual(try file.getAttribute("TEST_UINT")!.read(), data_uint)
        XCTAssertEqual(file.numberOfAttributes, 14)
        
        
        // legacy applications may wrote unsigned integers into singed NetCDF types
        let udata8 = try file.getAttribute("TEST_INT8")!.read()! as [UInt8]
        XCTAssertEqual(udata8, [123, 127, 129])
        let udata16 = try file.getAttribute("TEST_INT16")!.read()! as [UInt16]
        XCTAssertEqual(udata16, [1263, 1627, 32768, 32767])
        let udata32 = try file.getAttribute("TEST_INT32")!.read()! as [UInt32]
        XCTAssertEqual(udata32, [12653, 16627, 4294954529, 2147483648, 2147483647])
        let udata64 = try file.getAttribute("TEST_INT64")!.read()! as [UInt64]
        XCTAssertEqual(udata64, [12653, 16627, 18446744073709538849, 9223372036854775808, 9223372036854775807])
        let udata = try file.getAttribute("TEST_INT")!.read()! as [UInt]
        XCTAssertEqual(udata, [123, 345, 18446744073709550938, 9223372036854775808, 9223372036854775807])
    }

    static var allTests = [
        ("testCreateSimple", testCreateSimple),
        ("testAttributes", testAttributes),
    ]
}
