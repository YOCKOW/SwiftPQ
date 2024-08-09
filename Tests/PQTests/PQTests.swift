/* *************************************************************************************************
 PQTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGear
import XCTest
@testable import PQ
import SQLGrammar

let runInGitHubActions: Bool = ProcessInfo.processInfo.environment["GITHUB_ACTIONS"]?.lowercased() == "true"

let databaseName = "swiftpq_test"
let databaseUserName = "swiftpq_test"
let databasePassword = "swiftpq_test"

final class PQTests: XCTestCase {
  func test_BinaryRepresentation() {
    let data = Data([0x30, 0x31, 0x32, 0x33, 0x00])
    let rep = BinaryRepresentation(data: data)
    for ii in 0..<data.count {
      XCTAssertEqual(
        data[data.index(data.startIndex, offsetBy: ii)],
        rep[rep.index(rep.startIndex, offsetBy: ii)]
      )
    }
  }

  func test_host() async throws {
    let connection = try Connection(
      host: .localhost,
      database: databaseName,
      user: databaseUserName,
      password: databasePassword,
      parameters: [Connection.SSLMode.allow]
    )

    let connDB = await connection.database
    XCTAssertEqual(connDB, databaseName)

    let connUser = await connection.user
    XCTAssertEqual(connUser, databaseUserName)

    let connPassword = await connection.password
    XCTAssertEqual(connPassword, databasePassword)

    await connection.finish()
  }

  func test_ipAddress() async throws {
    func __test(_ ipAddressDescription: String, file: StaticString = #file, line: UInt = #line) async throws {
      let ipAddress = try XCTUnwrap(IPAddress(string: ipAddressDescription), file: file, line: line)
      let connection = try Connection(
        host: ipAddress,
        database: databaseName,
        user: databaseUserName,
        password: databasePassword
      )

      let connDB = await connection.database
      XCTAssertEqual(connDB, databaseName, file: file, line: line)

      let connUser = await connection.user
      XCTAssertEqual(connUser, databaseUserName, file: file, line: line)

      let connPassword = await connection.password
      XCTAssertEqual(connPassword, databasePassword, file: file, line: line)

      let connAddress = await connection.hostAddress
      XCTAssertEqual(connAddress, ipAddress)

      await connection.finish()
    }

    try await __test("127.0.0.1")
    try await __test("::1")
  }

  func test_oid() {
    XCTAssertEqual(OID.bool, OID(rawValue: 16))
  }

  func test_query_StringInterpolation() {
    XCTAssertEqual(
      Query.rawSQL("SELECT \(identifier: "a") FROM \(TableName(schema: "public", name: "my_table"));").command,
      "SELECT a FROM public.my_table;"
    )
    XCTAssertEqual(
      Query.rawSQL("ROW(\(integer: UInt(1)), \(float: 2.3), \(literal: "foo bar"))").command,
      "ROW(1, 2.3, 'foo bar')"
    )
//    XCTAssertEqual(
//      Query.rawSQL("WHERE \(#binOp("n" < 1000))").command,
//      "WHERE n < 1000"
//    )
  }

  func test_query() async throws {
    let connection = try Connection(
      host: .localhost,
      database: databaseName,
      user: databaseUserName,
      password: databasePassword
    )
    
    let tableName: TableName = "test_table"

    let creationResult = try await connection.execute(
      .createTable(
        tableName,
        definitions: [
          .column(name: "id", dataType: .integer),
          .column(name: "name", dataType: .characterVarying(16))
        ],
        ifNotExists: true
      )
    )
    XCTAssertEqual(creationResult, .ok)

    let dropResult = try await connection.execute(.dropTable(tableName, ifExists: false))
    XCTAssertEqual(dropResult, .ok)

//    let selectResult = try await connection.execute(.select(#const(1)))

    await connection.finish()
  }

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

    let connection = try Connection(
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

  func test_ValueConvertible() throws {
    func __assert<V, D>(
      _ value: V,
      expectedBinaryData data: D,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws where V: ValueConvertible, V: Equatable, D: DataProtocol {
      let binary = try XCTUnwrap(
        value.sqlBinaryData,
        "Failed to get binary data.",
        file: file,
        line: line
      )
      XCTAssertTrue(binary == data, file: file, line: line)

      let restored = try XCTUnwrap(
        V(sqlBinaryData: binary),
        "Failed to get original value.",
        file: file,
        line: line
      )
      XCTAssertEqual(value, restored, "Unexpected value.", file: file, line: line)
    }

    try __assert(Int8(0x12), expectedBinaryData: [0x12])
    try __assert(UInt8(0x34), expectedBinaryData: [0x34])
    try __assert(Int16(0x1234), expectedBinaryData: [0x12, 0x34])
    try __assert(UInt16(0x5678), expectedBinaryData: [0x56, 0x78])
    try __assert(Int32(0x12345678), expectedBinaryData: [0x12, 0x34, 0x56, 0x78])
    try __assert(UInt32(0x9ABCDEF0), expectedBinaryData: [0x9A, 0xBC, 0xDE, 0xF0])
    try __assert(Int64(0x123456789ABCDEF0), expectedBinaryData: [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])
    try __assert(UInt64.max, expectedBinaryData: Data(repeating: 0xFF, count: 8))
    try __assert(Float(-118.625), expectedBinaryData: [0xC2, 0xED, 0x40, 0x00])
    try __assert(Double.infinity, expectedBinaryData: [0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    try __assert("ABCD", expectedBinaryData: [0x41, 0x42, 0x43, 0x44])
  }
}
