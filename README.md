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

let file = try File.create(path: "test.nc", overwriteExisting: true)

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

## Features
- Abstract Swift data types to NetCDF external types
- Supported data types: `Float`, `Double`, `String`, `Int8`, `Int16`, `Int32`, `Int64`, `Int`, `UInt16`, `UInt32`, `UInt64` and `UInt`
- Throws NetCDF library errors as exceptions
- Thread safe. Access to the netCDF C API is serialised with locks.

## Limitations
- User defined data tyes not yet implemented

## Roadmap
- Data type conversions

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
