// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription
import CompilerPluginSupport

let postgresIncludeDirectory: String? = try ({ () throws -> String? in
  func __run(_ exePath: URL, arguments: [String]?) throws -> String? {
    let process = Process()
    let stdout = Pipe()
    process.executableURL = exePath
    process.standardOutput = stdout
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }
    let stdoutData = stdout.fileHandleForReading.availableData
    return String(data: stdoutData, encoding: .utf8)
  }

  guard let pgConfigPath =  try __run(
    URL(fileURLWithPath: "/bin/sh"),
    arguments: ["-c", "which pg_config"]
  ) else {
    print("pg_config not found.")
    return nil
  }
  return try __run(
    URL(fileURLWithPath: pgConfigPath._trimmed),
    arguments: ["--includedir"]
  )?._trimmed
})()

let cPostgreSQLCSettings: [CSetting] = ({
  var settings: [CSetting] = []
  if let postgresIncludeDirectory {
    settings.append(.unsafeFlags(["-I", postgresIncludeDirectory]))
  }
  return settings
})()

let swiftSyntaxVersion: Version = ({
  #if compiler(>=5.10)
  return "510.0.1"
  #else
  return "509.1.1"
  #endif
})()

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
    .library(name: "CPostgreSQL", type: .static, targets: ["CPostgreSQL"]),
    .library(name: "CLibPQ", targets: ["CLibPQ"]),
    .library(name: "SwiftPQ", targets: ["SQLGrammar", "PQ"]),
  ],
  dependencies: [
    .package(url:"https://github.com/YOCKOW/SwiftNetworkGear.git", "0.16.6"..<"2.0.0"),
    .package(url:"https://github.com/YOCKOW/SwiftUnicodeSupplement.git", from: "1.4.0"),
    .package(url:"https://github.com/YOCKOW/ySwiftExtensions.git", from: "1.10.1"),

    // For Macros
    .package(url: "https://github.com/apple/swift-syntax.git", from: swiftSyntaxVersion),
    .package(url: "https://github.com/YOCKOW/swift-system.git", from: "1.3.2"),
  ],
  targets: [
      // Targets are the basic building blocks of a package, defining a module or a test suite.
      // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "CPostgreSQL",
      cSettings: cPostgreSQLCSettings
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
        "CPostgreSQL",
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SystemPackage", package: "swift-system"),
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
        "CLibPQ",
        "CPostgreSQL",
        "PQMacros",
        "SQLGrammar",
        "SwiftNetworkGear",
        "SwiftUnicodeSupplement",
        "ySwiftExtensions",
      ]
    ),
    .testTarget(
      name: "PQMacrosTests",
      dependencies: [
        "CPostgreSQL",
        "PQMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SQLGrammarTests",
      dependencies: [
        "CPostgreSQL",
        "SwiftNetworkGear",
        "SQLGrammar",
      ]
    ),
    .testTarget(
      name: "PQTests",
      dependencies: [
        "CPostgreSQL",
        "PQ",
        "SQLGrammar",
      ]
    ),
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

private extension Character {
  var _isWhitespaceOrNewline: Bool {
    return self.isWhitespace || self.isNewline
  }
}

private extension String {
  var _trimmed: String {
    guard let firstIndex = self.firstIndex(where: { !$0._isWhitespaceOrNewline }),
          let lastIndex = self.lastIndex(where: { !$0._isWhitespaceOrNewline }) else {
      return ""
    }
    return String(self[firstIndex...lastIndex])
  }
}
