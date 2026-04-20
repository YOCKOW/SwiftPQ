// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription
import CompilerPluginSupport

let swiftSyntaxVersion: Version = ({
  #if compiler(>=6.3)
  return "603.0.0"
  #elseif compiler(>=6.2)
  return "602.0.0"
  #elseif compiler(>=6.1)
  return "601.0.1"
  #elseif compiler(>=6)
  return "600.0.1"
  #elseif compiler(>=5.10)
  return "510.0.3"
  #else
  return "509.1.1"
  #endif
})()

let package = Package(
  name: "PQ",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .watchOS(.v9),
    .tvOS(.v16),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "CLibECPG", targets: ["CLibECPG"]),
    .library(name: "CLibPQ", targets: ["CLibPQ"]),
    .library(name: "SwiftPQ", targets: ["SQLGrammar", "PQ"]),
  ],
  dependencies: [
    .package(url: "https://github.com/YOCKOW/SwiftNetworkGear.git", "0.20.1"..<"2.0.0"),
    .package(url: "https://github.com/YOCKOW/SwiftRanges.git", from: "4.0.2"),
    .package(url: "https://github.com/YOCKOW/SwiftUnicodeSupplement.git", from: "2.0.1"),
    .package(url: "https://github.com/YOCKOW/ySwiftExtensions.git", from: "2.1.0"),

    // For Macros
    .package(url: "https://github.com/apple/swift-syntax.git", from: swiftSyntaxVersion),
  ],
  targets: [
      // Targets are the basic building blocks of a package, defining a module or a test suite.
      // Targets can depend on other targets in this package and products from dependencies.
    .systemLibrary(
      name: "CLibECPG",
      pkgConfig: "libecpg libpgtypes",
      providers: [
        .brew(["postgresql", "libpq"]),
        .apt(["libecpg-dev", "libpgtypes3"]),
      ]
    ),
    .systemLibrary(
      name: "CLibPQ",
      pkgConfig: "libpq",
      providers: [
        .brew(["postgresql", "libpq"]),
        .apt(["libpq-dev"]),
      ]
    ),
    .macro(
      name: "PQMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SQLGrammar",
      dependencies: [
        "SwiftUnicodeSupplement",
        "PQMacros",
      ]
    ),
    .target(
      name: "PQ",
      dependencies: [
        "CLibECPG",
        "CLibPQ",
        "PQMacros",
        "SQLGrammar",
        "SwiftNetworkGear",
        "SwiftRanges",
        "SwiftUnicodeSupplement",
        "ySwiftExtensions",
      ]
    ),
    .testTarget(
      name: "PQMacrosTests",
      dependencies: [
        "PQMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SQLGrammarTests",
      dependencies: [
        "SwiftNetworkGear",
        "SQLGrammar",
      ]
    ),
    .testTarget(
      name: "PQTests",
      dependencies: [
        "PQ",
        "SQLGrammar",
      ]
    ),
  ],
  swiftLanguageModes: [
    .v5,
    .v6
  ]
)

let repoDirPath = String(#filePath).split(separator: "/", omittingEmptySubsequences: false).dropLast().joined(separator: "/")
if ProcessInfo.processInfo.environment["YOCKOW_USE_LOCAL_PACKAGES"] != nil {
  func localPath(with url: String) -> String {
    guard let url = URL(string: url) else { fatalError("Unexpected URL.") }
    let dirName = url.deletingPathExtension().lastPathComponent
    return "../\(dirName)"
  }
  package.dependencies = package.dependencies.map {
    guard case .sourceControl(_, let location, _) = $0.kind else { return $0 }
    let depRelPath = localPath(with: location)
    guard FileManager.default.fileExists(atPath: "\(repoDirPath)/\(depRelPath)") else {
      return $0
    }
    return .package(path: depRelPath)
  }
}
