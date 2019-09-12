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

// TODO docs
```

2. Read NetCDF files

```swift
import SwiftNetCDF

// TODO docs
```

## Limitations
- User defined data tyes not yet implemented


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
