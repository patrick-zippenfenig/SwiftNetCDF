// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftNetCDF",
    products: [
        .library(name: "SwiftNetCDF", targets: ["SwiftNetCDF"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(
            name: "CNetCDF",
            pkgConfig: "netcdf",
            providers: [.brew(["netcdf"]), .apt(["libnetcdf-dev"])]
        ),
        .target(name: "SwiftNetCDF", dependencies: ["CNetCDF"]),
        .testTarget(name: "SwiftNetCDFTests", dependencies: ["SwiftNetCDF"]),
    ]
)
