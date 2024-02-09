/* *************************************************************************************************
 PQTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGear
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

  func test_token() throws {
    let positionalParameter = try SingleToken.positionalParameter(1)
    XCTAssertEqual(positionalParameter.description, "$1")

    let column = ColumnReference(tableName: TableName(schema: "public", name: "my_table"), columnName: "my_column")
    XCTAssertEqual(column.description, "public.my_table.my_column")

    let subscriptExp1 = Subscript(expression: positionalParameter, parameter: .index(4))
    XCTAssertEqual(subscriptExp1.description, "$1[4]")

    let subscriptExp2 = Subscript(expression: column, parameter: .slice(lower: 12, upper: 24))
    XCTAssertEqual(subscriptExp2.description, "public.my_table.my_column[12:24]")

    let subscriptExp3 = Subscript(expression: subscriptExp2, parameter: .index(2))
    XCTAssertEqual(subscriptExp3.description, "public.my_table.my_column[12:24][2]")

    let fieldSelection1 = FieldSelection(expression: TableName(name: "my_table"), field: .name("my_column"))
    XCTAssertEqual(fieldSelection1.description, "my_table.my_column")

    let fieldSelection2 = FieldSelection(expression: TableName(schema: "public", name: "my_table"), field: .name("my_column"))
    XCTAssertEqual(fieldSelection2.description, "(public.my_table).my_column")

    let fieldSelection3 = FieldSelection(expression: ColumnReference(columnName: "my_column"), field: .all)
    XCTAssertEqual(fieldSelection3.description, "(my_column).*")

    let binaryOperator = BinaryInfixOperatorInvocation(SingleToken.integer(2), .plus, SingleToken.integer(3))
    XCTAssertEqual(binaryOperator.description, "2 + 3")

    let unaryPrefixOperator1 = UnaryPrefixOperatorInvocation(.minus, SingleToken.integer(2))
    XCTAssertEqual(unaryPrefixOperator1.description, "-2")

    let unaryPrefixOperator2 = UnaryPrefixOperatorInvocation(.minus, SingleToken.integer(-2))
    XCTAssertEqual(unaryPrefixOperator2.description, "-(-2)")

    let function1 = FunctionCall.concatenate(SingleToken.string("A"), SingleToken.string("B"))
    XCTAssertEqual(function1.description, "CONCAT('A', 'B')")

    let orderBy1 = try SortClause([
      .init(expression: BinaryInfixOperatorInvocation(
        SingleToken.identifier("a"), .plus, SingleToken.identifier("b")
      )),
      .init(expression: SingleToken.identifier("c"), direction: .descending, nullOrdering: .last),
    ])
    XCTAssertEqual(orderBy1.description, "ORDER BY a + b, c DESC NULLS LAST")

    let dropTableQuery = Query.dropTable(schema: "public", name: "my_table", ifExists: true)
    XCTAssertEqual(dropTableQuery.command, "DROP TABLE IF EXISTS public.my_table;")
  }

  func test_query() async throws {
    let connection = try Connection(
      host: XCTUnwrap(Domain("localhost")),
      database: databaseName,
      user: databaseUserName,
      password: databasePassword
    )

    let creationResult = try await connection.execute(.rawSQL("""
      CREATE TABLE IF NOT EXISTS test_table (
        id integer,
        name varchar(16)
      );
    """))
    XCTAssertEqual(creationResult, .ok)

    let dropResult = try await connection.execute(.dropTable(name: "test_table", ifExists: true))
    XCTAssertEqual(dropResult, .ok)

    await connection.finish()
  }
}
