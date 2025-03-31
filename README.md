# SwiftNetCDF
![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg) ![SPM](https://img.shields.io/badge/SPM-compatible-green.svg) ![Platforms](https://img.shields.io/badge/Platforms-macOS%20Linux-green.svg) [![codebeat badge](https://codebeat.co/badges/cca7b706-6c03-4b0a-ad0b-f730563e0ef5)](https://codebeat.co/projects/github-com-patrick-zippenfenig-swiftnetcdf-master) [![Test](https://github.com/patrick-zippenfenig/SwiftNetCDF/actions/workflows/test.yml/badge.svg)](https://github.com/patrick-zippenfenig/SwiftNetCDF/actions/workflows/test.yml)

SwiftNetCDF is a library to read and write NetCDF files in Swift with type safety.

## Installation
1. SwiftNetCDF requires the NetCDF C client library which can be installed on Mac with `brew install netcdf` or on Linux with `sudo apt install libnetcdf-dev`.

2. Add `SwiftNetCDF` as a dependency to your `Package.swift`

```swift
  dependencies: [
    .package(url: "https://github.com/patrick-zippenfenig/SwiftNetCDF.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "MyApp", dependencies: ["SwiftNetCDF"])
  ]
```

3. Build your project:

```bash
$ swift build
```

## Usage
1. Write NetCDF files

```swift
import SwiftNetCDF

let data = [Int32(0), 3, 4, 6, 12, 45, 89, ...]

var file = try NetCDF.create(path: "test.nc", overwriteExisting: true)

try file.setAttribute("TITLE", "My data set")

let dimensions = [
  try file.createDimension(name: "LAT", length: 10),
  try file.createDimension(name: "LON", length: 5)
]

let variable = try file.createVariable(name: "MyData", type: Int32.self, dimensions: dimensions)
try variable.write(data)
```

2. Read NetCDF files

```swift
import SwiftNetCDF

guard let file = try NetCDF.open(path: "test.nc", allowUpdate: false) else {
    fatalError("File test.nc does not exist")
}

guard let title: String = try file.getAttribute("TITLE")?.read() else {
    fatalError("TITLE attribute not available or not a String")
}

guard let variable = file.getVariable(name: "MyData") else {
    fatalError("No variable named MyData available")
}
guard let typedVariable = variable.asType(Int32.self) else {
    fatalError("MyData is not a Int32 type")
}
let data2 = try typedVariable.read(offset: [1,1], count: [2,2])
```

3. Using groups, unlimited dimensions and compression

```swift
import SwiftNetCDF

let file = try NetCDF.create(path: "test.nc", overwriteExisting: true)

// Create new group. Analog the `getGroup(name: )` function can be used for existing groups
let subGroup = try file.createGroup(name: "GROUP1")

let dimLat = try subGroup.createDimension(name: "LAT", length: 10)
let dimLon = try subGroup.createDimension(name: "LON", length: 5, isUnlimited: true)

var lats = try subGroup.createVariable(name: "LATITUDES", type: Float.self, dimensions: [dimLat])
var lons = try subGroup.createVariable(name: "LONGITUDES", type: Float.self, dimensions: [dimLon])

try lats.write((0 ..< 10).map(Float.init))
try lons.write((0 ..< 5).map(Float.init))

// `data` is of type `VariableGeneric<Float>`. Define functions can be accessed via `data.variable`
var data = try subGroup.createVariable(name: "DATA", type: Float.self, dimensions: [dimLat, dimLon])

// Enable compression, shuffle filter and chunking
try data.defineDeflate(enable: true, level: 6, shuffle: true)
try data.defineChunking(chunking: .chunked, chunks: [1, 5])

/// Because the latitude dimension is unlimited, we can write more than the defined size
let array = (0 ..< 1000).map(Float.init)
try data.write(array, offset: [0, 0], count: [10, 100])

/// The check the new dimension count
XCTAssertEqual(data.dimensionsFlat, [10, 100])

// even more data at an offset
try data.write(array, offset: [0, 100], count: [10, 100])

XCTAssertEqual(data.dimensionsFlat, [10, 200])
```

4. Discover the structure of a NetCDF file

```swift
import SwiftNetCDF

guard let file = try NetCDF.open(path: "test.nc", allowUpdate: false) else {
    fatalError("File test.nc does not exist")
}

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

    for a in try group.getAttributes() {
        print("Attribute: \(a.name) \(a.length) \(a.type.asExternalDataType()!)")
    }

    for subgroup in group.getGroups() {
        printGroup(subgroup)
    }
}

// The root entry point of a NetCDF file is also a `Group`
printGroup(file)
```

Output:
```
Group: /
Group: GROUP1
Dimension: LAT 10 false
Dimension: LON 200 true
Variable: LATITUDES float
Variable dimension: LAT 10 false
Variable: LONGITUDES float
Variable dimension: LON 200 true
Variable: DATA float
Variable dimension: LAT 10 false
Variable dimension: LON 200 true
```

## Features
- Abstract Swift data types to NetCDF external types
- Supported data types: `Float`, `Double`, `String`, `Int8`, `Int16`, `Int32`, `Int64`, `Int`, `UInt16`, `UInt32`, `UInt64` and `UInt`
- Returns `nil` for missing files, variables, attributes or data-type mismatch
- Exceptions are thrown for NetCDF library errors
- Uses generics to ensure the correct type is being used
- Thread safe. Access to the netCDF C API is serialized with thread locks

## Limitations
- User defined data types not yet implemented

## Quick function reference
SwiftNetCDF uses a simple data structures to organize access to NetCDF functions. The most important once are listed below.

```swift
struct NetCDF {
    static func create(path: String, overwriteExisting: Bool) -> Group
    static func open(path: String, allowUpdate: Bool) -> Group?

    /// Opens a NetCDF file from memory in read-only mode
    static func open(memory: UnsafeRawBufferPointer)) -> Group?
}

struct Group {
    let name: String

    func getGroup(name: String) -> Group?
    func getGroups() -> [Group]
    func createGroup(name: String) -> Group

    func getDimensions() -> [Dimension]
    func createDimension(name: String, length: Int, isUnlimited: Bool = false) -> Dimension

    func getVariable(name: String) -> Variable?
    func getVariables() -> [Variable]
    func createVariable<T>(name: String, type: T.Type, dimensions: [Dimension]) -> VariableGeneric<T>

    func getAttribute(_ key: String) -> Attribute?
    func getAttributes() -> [Attribute]
    func setAttribute<T>(_ name: String, _ value: T)
    func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: [T])
}

struct Variable {
    let name: String

    var dimensions: [Dimension]
    var dimensionsFlat: [Int]

    /// `Nil` in case of type mismatch
    func asType<T>(_ of: T.Type) -> VariableGeneric<T>?

    func defineDeflate(enable: Bool, level: Int = 6, shuffle: Bool = false)
    func defineChunking(chunking: VarId.Chunking, chunks: [Int])

    // Same get/set attribute functions as a Group
}

struct VariableGeneric<T> {
    func read() -> [T]
    func read(offset: [Int], count: [Int]) -> [T]
    func read(offset: [Int], count: [Int], stride: [Int]) -> [T]

    func write(_ data: [T])
    func write(_ data: [T], offset: [Int], count: [Int])
    func write(_ data: [T], offset: [Int], count: [Int], stride: [Int])

    // Same get/set attribute functions as a Group
    // Same define functions as Variable
}

struct Dimension {
    let name: String
    let length: Int
    let isUnlimited: Bool
}

struct Attribute {
    let name: String
    let length: Int

    func read<T: NetcdfConvertible>() throws -> T?
    func read<T: NetcdfConvertible>() throws -> [T]?
}
```


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
