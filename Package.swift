// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PQ",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "CLibPQ", targets: ["CLibPQ"]),
    .library(name: "SwiftPQ", targets: ["PQ"]),
  ],
  targets: [
      // Targets are the basic building blocks of a package, defining a module or a test suite.
      // Targets can depend on other targets in this package and products from dependencies.
    .systemLibrary(
      name: "CLibPQ",
      pkgConfig: "libpq",
      providers: [
        .brew(["postgresql", "libpq"]),
        .apt(["libpq-dev"]),
      ]
    ),
    .target(name: "PQ", dependencies: ["CLibPQ"]),
    .testTarget(name: "PQTests", dependencies: ["PQ"]),
  ]
)

