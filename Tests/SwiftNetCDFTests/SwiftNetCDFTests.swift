import XCTest
/*@testable*/ import SwiftNetCDF

final class SwiftNetCDFTests: XCTestCase {
    /**
     Create a simple NetCDF file and write some data.
     Afterwards read the data again and check if it is the same.
     */
    func testCreateSimple() throws {
        let data = (Int32(0)..<50).map{$0}
        
        let file = try File.create(path: "test.nc", overwriteExisting: true)
        try file.setAttribute("TITLE", "My data set")
        
        let dimensions = [
            try file.createDimension(name: "LAT", length: 10),
            try file.createDimension(name: "LON", length: 5)
        ]
        
        var variable = try file.createVariable(name: "MyData", type: Int32.self, dimensions: dimensions)
        try variable.write(data)
        file.sync()
        
        
        // Open the same file again and read the data
        let file2 = try File.open(path: "test.nc", allowWrite: false)
        guard let title: String = try file2.getAttribute("TITLE")?.read() else {
            fatalError("TITLE attribute not available or not a String")
        }
        XCTAssertEqual(title, "My data set")
        
        guard let variable2 = file2.getVariable(name: "MyData") else {
            fatalError("No variable named MyData available")
        }
        guard let typedVariable = variable2.asType(Int32.self) else {
            fatalError("MyData is not a Int32 type")
        }
        let data2 = try typedVariable.read(offset: [1,1], count: [2,2])
        
        XCTAssertEqual([6, 7, 11, 12], data2)
    }
    
    func testCreateGroups() throws {
        let file = try File.create(path: "test.nc", overwriteExisting: true)
        
        // Create new group. Analog the `getGroup(name: )` function can be used for existing groups
        let subGroup = try file.createGroup(name: "GROUP1")
        
        let dimLat = try subGroup.createDimension(name: "LAT", length: 10)
        let dimLon = try subGroup.createDimension(name: "LON", length: 5, isUnlimited: true)
        
        var lats = try subGroup.createVariable(name: "LATITUDES", type: Float.self, dimensions: [dimLat])
        var lons = try subGroup.createVariable(name: "LONGITUDES", type: Float.self, dimensions: [dimLon])
        
        try lats.write((0..<10).map(Float.init))
        try lons.write((0..<5).map(Float.init))
        
        // `data` is of type `VariableGeneric<Float>`. Define functions can be accessed via `data.variable`
        var data = try subGroup.createVariable(name: "DATA", type: Float.self, dimensions: [dimLat, dimLon])
        
        // Enable compression, shuffle filter and chunking
        try data.variable.defineDeflate(enable: true, level: 6, shuffle: true)
        try data.variable.defineChunking(chunking: .chunked, chunks: [1, 5])
        
        /// Because the latitude dimension is unlimted, we can write more than the defined size
        let array = (0..<1000).map(Float.init)
        try data.write(array, offset: [0, 0], count: [10, 100])
        
        /// The check the new dimension count
        XCTAssertEqual(data.variable.dimensionsFlat, [10, 100])
        
        // even more data at an offset
        try data.write(array, offset: [0, 100], count: [10, 100])
        
        XCTAssertEqual(data.variable.dimensionsFlat, [10, 200])
        
        
        /// Recursively print all groups
        func printGroup(_ group: Group) {
            print("Group: \(group.name)")
            
            for d in group.getDimensions() {
                print("Dimension: \(d.name) \(d.length) \(d.isUnlimited)")
            }
            
            for v in group.getVariables() {
                print("Variable: \(v.name) \(v.type.asExternalDataType()!)")
                for d in v.dimensions {
                    print("Variable dimension: \(d.name) \(d.length) \(d.isUnlimited)")
                }
            }
            
            for a in try! group.getAttributes() {
                print("Attribute: \(a.name) \(a.length) \(a.type.asExternalDataType()!)")
            }
            
            for subgroup in group.getGroups() {
                printGroup(subgroup)
            }
        }
        
        // The root entry point of a NetCDF file is also a `Group`
        printGroup(file)
    }
    
    /**
     Test groups with subgroups
     */
    func testGroups() throws {
        let file = try File.create(path: "test.nc", overwriteExisting: true, useNetCDF4: true)
        let group1 = try file.createGroup(name: "GROUP1")
        XCTAssertNotNil(file.getGroup(name: "GROUP1"))
        XCTAssertNil(file.getGroup(name: "NotExistingGroup"))
        XCTAssertNil(file.getVariable(name: "TEST_VAR"))
        let dim = try file.createDimension(name: "MYDIM", length: 5)
        let _ = try file.createVariable(name: "TEST_VAR", type: Int32.self, dimensions: [dim])
        XCTAssertNotNil(file.getVariable(name: "TEST_VAR"))
        
        /// Subgrup in subgroup
        XCTAssertNil(group1.getGroup(name: "GROUP1_1"))
        let group1_1 = try group1.createGroup(name: "GROUP1_1")
        XCTAssertNotNil(group1.getGroup(name: "GROUP1_1"))
        XCTAssertNil(group1_1.getVariable(name: "TEST_VAR"))
        let _ = try group1_1.createVariable(name: "TEST_VAR", type: Int32.self, dimensions: [dim])
        XCTAssertNotNil(group1_1.getVariable(name: "TEST_VAR"))
    }
    
    /// TODO unit test for subgroups.. also chech missing
    
    /**
     Write and read all attribute data-types
     */
    func testAttributes() throws {
        let data_float = [Float(42), 34, 123]
        let file_raw = try File.create(path: "test.nc", overwriteExisting: true, useNetCDF4: true)
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
        
        let attributes = try file.getAttributes()
        let names = attributes.map{ $0.name }.joined(separator: ", ")
        XCTAssertEqual(names,"TEST_FLOAT, TEST_FLOAT_NAN, TEST_DOUBLE, TEST_STRING, TEST_INT8, TEST_INT16, TEST_INT32, TEST_INT64, TEST_INT, TEST_UINT8, TEST_UINT16, TEST_UINT32, TEST_UINT64, TEST_UINT")
    }

    static var allTests = [
        ("testCreateSimple", testCreateSimple),
        ("testCreateGroups", testCreateGroups),
        ("testGroups", testGroups),
        ("testAttributes", testAttributes),
    ]
}
