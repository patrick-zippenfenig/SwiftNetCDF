# SwiftNetCDF
![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg) ![SPM](https://img.shields.io/badge/SPM-compatible-green.svg) ![Platforms](https://img.shields.io/badge/Platforms-macOS%20Linux-green.svg) [![codebeat badge](https://codebeat.co/badges/cca7b706-6c03-4b0a-ad0b-f730563e0ef5)](https://codebeat.co/projects/github-com-patrick-zippenfenig-swiftnetcdf-master) [![CircleCI](https://circleci.com/gh/patrick-zippenfenig/SwiftNetCDF/tree/master.svg?style=svg)](https://circleci.com/gh/patrick-zippenfenig/SwiftNetCDF/tree/master) 

SwiftNetCDF is a library to read and write NetCDF files.

## Installation
1. SwiftNetCDF requires the NetCDF C client library which can be installed on Mac with `brew install netcdf` or on Linux with `sudo apt install libnetcdf-dev`.

2. Add `SwiftNetCDF` as a dependency to your `Package.swift`

```swift
  dependencies: [
    .package(url: "https://github.com/patrick-zippenfenig/SwiftNetCDF.git", from: "0.0.0")
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

var file = try File.create(path: "test.nc", overwriteExisting: true)

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

let file = try File.open(path: "test.nc", allowWrite: false)

guard let title: String = try file.getAttribute("TITLE")?.read() else {
    fatalError("TITLE attribute not available or not a String")
}

guard let variable = file.getVariable(byName: "MyData") else {
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
```

4. Discover the structure of a NetCDF file

```
import SwiftNetCDF

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
- Throws NetCDF library errors as exceptions
- Thread safe. Access to the netCDF C API is serialised with thread locks

## Limitations
- User defined data tyes not yet implemented

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
