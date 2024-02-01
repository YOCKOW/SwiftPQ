/* *************************************************************************************************
 PQTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import PQ

let runInGitHubActions: Bool = ProcessInfo.processInfo.environment["GITHUB_ACTIONS"]?.lowercased() == "true"

let databaseName = "swiftpq_test"
let databaseUserName = "swiftpq_test"
let databasePassword = "swiftpq_test"

final class PQTests: XCTestCase {
  func test_socket() async throws {
    if runInGitHubActions {
      print("Skip this test because PostgreSQL's UNIX socket is disabled by ikalnytskyi/action-setup-postgres.")
      return
    }

    #if os(macOS)
    let socketDirectory = "/tmp"
    #elseif os(Linux)
    let socketDirectory = "/var/run/postgresql"
    #else
    #error("Unsupported OS.")
    #endif

    let connection = try PGConnection(
      unixSocketDirectoryPath: socketDirectory,
      database: databaseName,
      user: databaseUserName,
      password: databasePassword
    )

    let connDB = await connection.database
    XCTAssertEqual(connDB, databaseName)

    let connUser = await connection.user
    XCTAssertEqual(connUser, databaseUserName)

    let connPassword = await connection.password
    XCTAssertEqual(connPassword, databasePassword)

    await connection.finish()
  }
}
