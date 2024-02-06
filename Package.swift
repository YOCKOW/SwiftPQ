// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PQ",
  platforms: [
    .macOS("10.15.4"),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "CLibPQ", targets: ["CLibPQ"]),
    .library(name: "SwiftPQ", targets: ["PQ"]),
  ],
  dependencies: [
    .package(url:"https://github.com/YOCKOW/SwiftNetworkGear.git", "0.16.6"..<"2.0.0"),
    .package(url:"https://github.com/YOCKOW/SwiftUnicodeSupplement.git", from: "1.4.0"),
    .package(url:"https://github.com/YOCKOW/ySwiftExtensions.git", from: "1.10.1"),
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
    .target(
      name: "PQ",
      dependencies: [
        "CLibPQ",
        "SwiftNetworkGear",
        "SwiftUnicodeSupplement",
        "ySwiftExtensions",
      ]
    ),
    .testTarget(name: "PQTests", dependencies: ["PQ"]),
  ]
)

import Foundation
if ProcessInfo.processInfo.environment["YOCKOW_USE_LOCAL_PACKAGES"] != nil {
  func localPath(with url: String) -> String {
    guard let url = URL(string: url) else { fatalError("Unexpected URL.") }
    let dirName = url.deletingPathExtension().lastPathComponent
    return "../\(dirName)"
  }
  package.dependencies = package.dependencies.map {
    guard case .sourceControl(_, let location, _) = $0.kind else { fatalError("Unexpected dependency.") }
    return .package(path: localPath(with: location))
  }
}
