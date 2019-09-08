# SwiftNetCDF


## Development
C module maps [do not support cross-platform](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md#cross-platform-module-maps) yet. Therefore a Overrides.xcconfig is used to set the path for libraries installed with brew.

Mac:
- `brew install netcdf`
- Build xcode project `swift package generate-xcodeproj --xcconfig-overrides=Overrides.xcconfig`
- Run tests `swift test -Xlinker -L/usr/local/lib/`

Linnux
- `apt install libnetcdf-dev`
