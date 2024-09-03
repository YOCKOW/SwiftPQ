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

let databaseName = ProcessInfo.processInfo.environment["SWIFTPQ_TEST_DB_NAME"] ?? "swiftpq_test"
let databaseUserName = ProcessInfo.processInfo.environment["SWIFTPQ_TEST_DB_USER_NAME"] ?? "swiftpq_test"
let databasePassword = ProcessInfo.processInfo.environment["SWIFTPQ_TEST_DB_PASSWORD"] ?? "swiftpq_test"

final class PQTests: XCTestCase {
  func newConnection(
    host: Domain = .localhost,
    parameters: [any ConnectionParameter]? = nil
  ) throws -> Connection {
    return try Connection(
      host: host,
      port: nil,
      database: databaseName,
      user: databaseUserName,
      password: databasePassword,
      parameters: parameters
    )
  }

  func newConnection(
    host: IPAddress,
    parameters: [any ConnectionParameter]? = nil
  ) throws -> Connection {
    return try Connection(
      host: host,
      port: nil,
      database: databaseName,
      user: databaseUserName,
      password: databasePassword,
      parameters: parameters
    )
  }

  func newConnection(unixSocketDirectoryPath path: String) throws -> Connection {
    return try Connection(
      unixSocketDirectoryPath: path,
      port: nil,
      database: databaseName,
      user: databaseUserName,
      password: databasePassword
    )
  }

  func connecting<Result>(
    host: Domain = .localhost,
    parameters: [any ConnectionParameter]? = nil,
    job: (Connection) async throws -> Result
  ) async throws -> Result {
    let connection = try newConnection(host: host, parameters: parameters)
    let result = try await job(connection)
    await connection.finish()
    return result
  }

  func assertTuples(
    _ result: QueryResult,
    expectedNumberOfRows: Int,
    expectedNumberOfColumns: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> QueryResult.Table? {
    guard case .tuples(let table) = result else {
      XCTFail("Result is not tuples.", file: file, line: line)
      return nil
    }
    guard table.count == expectedNumberOfRows else {
      XCTFail("Unexpected number of rows.", file: file, line: line)
      return nil
    }
    guard table.numberOfColumns == expectedNumberOfColumns else {
      XCTFail("Unexpected number of columns.", file: file, line: line)
      return nil
    }
    return table
  }

  // MARK: - Tests

  func test_BinaryRepresentation() {
    let data = Data([0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x00])
    let representation = BinaryRepresentation(data: data)
    for ii in 0..<data.count {
      XCTAssertEqual(
        data[data.index(data.startIndex, offsetBy: ii)],
        representation[representation.index(representation.startIndex, offsetBy: ii)]
      )
    }

    do {
      // enumeration
      var counter = 0
      for byte in representation {
        counter += 1
        XCTAssertTrue(byte == 0x00 || (0x30...0x39).contains(byte))
      }
      XCTAssertEqual(counter, representation.count)

      counter = 0
      for (ii, byte) in representation.enumerated() {
        counter += 1
        XCTAssertTrue(byte == 0x00 || ii == byte - 0x30)
      }
      XCTAssertEqual(counter, representation.count)
    }

    XCTAssertEqual(
      representation.debugDescription,
      """
      BinaryRepresentation(11 bytes):
      30 31 32 33 34 35 36 37
      38 39 00
      """
    )

  }

  func test_connectionParameterStatus() async throws {
    try await connecting {
      let dateStyle = await $0.dateStyle
      XCTAssertNotNil(dateStyle)

      let intervalStyle = await $0.intervalStyle
      XCTAssertNotNil(intervalStyle)

      let timeZone = await $0.timeZone
      XCTAssertNotNil(timeZone)
    }
  }

  func test_Date() async throws {
    XCTAssertTrue(try ({ () throws -> Bool in
      let date = try XCTUnwrap(Date("2001-02-28"))
      let ymd = date.yearMonthDay
      return (
        ymd.year == 2001
        && ymd.month == 2
        && ymd.day == 28
      )
    })())
    XCTAssertEqual(Date("1999-03-13"), Date(year: 1999, month: 3, day: 13))

    do {
      var date = try XCTUnwrap(Date("2002-04-01"))
      date.day += 1
      XCTAssertEqual(date.description, "2002-04-02")
      date.month += 1
      XCTAssertEqual(date.description, "2002-05-02")
      date.year += 22
      XCTAssertEqual(date.description, "2024-05-02")
    }


    try await connecting {
      var result: QueryResult!

      result = try await $0.execute(.select(#DATE("2024-08-27")), resultFormat: .text)
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .date)
        XCTAssertEqual(field.value.as(Date.self)?.sqlStringValue, "2024-08-27")
      }

      result = try await $0.execute(.select(#DATE("2024-08-27")), resultFormat: .binary)
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .date)
        XCTAssertEqual(field.value.as(Date.self)?.sqlStringValue, "2024-08-27")
      }

      result = try await $0.execute(
        .select(#paramExpr(1)),
        parameters: [try XCTUnwrap(Date(sqlStringValue: "1983-10-03"))]
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .date)
        XCTAssertEqual(field.value.as(Date.self)?.sqlStringValue, "1983-10-03")
      }
    }
  }

  func test_host() async throws {
    let connection = try newConnection(parameters: [Connection.SSLMode.allow])

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
      let connection = try newConnection(host: ipAddress)

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
    let connection = try newConnection()
    
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

    await connection.finish()
  }

  func test_query_binaryResult_bool() async throws {
    try await connecting {
      let result = try await $0.execute(.select(#TRUE, #FALSE), resultFormat: .binary)
      if let boolTable = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 2) {
        let row = boolTable[0]
        let trueField = row[0]
        let falseField = row[1]
        XCTAssertEqual(trueField.oid, .bool)
        XCTAssertEqual(falseField.oid, .bool)
        XCTAssertEqual(trueField.value.as(Bool.self), true)
        XCTAssertEqual(falseField.value.as(Bool.self), false)
      }
    }
  }

  func test_query_binaryResult_data() async throws {
    try await connecting {
      let result = try await $0.execute(
        .select(BinaryInfixTypeCastOperatorInvocation(#const("\\xDEADBEEF"), as: .bytea)),
        resultFormat: .binary
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .bytea)
        XCTAssertEqual(field.value.as(Data.self), Data([0xDE, 0xAD, 0xBE, 0xEF]))
      }
    }
  }

  func test_query_binaryResult_decimal() async throws {
    try await connecting { (connection) async throws -> Void in
      func __assertDecimal(
        _ decimalDescription: String,
        expectedDecimal: Decimal,
        file: StaticString = #filePath,
        line: UInt = #line
      ) async throws {
        let decimalResult = try await connection.execute(
          .rawSQL("SELECT \(raw: decimalDescription)::decimal;"),
          resultFormat: .binary
        )
        if let decimalTable = assertTuples(
          decimalResult,
          expectedNumberOfRows: 1,
          expectedNumberOfColumns: 1,
          file: file,
          line: line
        ) {
          let field = decimalTable[0][0]
          XCTAssertEqual(field.oid, .numeric, "Unexpected OID.", file: file, line: line)
          XCTAssertEqual(field.value.as(Decimal.self), expectedDecimal, "Unexpected Decimal value.", file: file, line: line)
        }
      }

      try await __assertDecimal("12345.67", expectedDecimal: Decimal(sign: .plus, exponent: -2, significand: 1234567))
      try await __assertDecimal("1234567", expectedDecimal: Decimal(sign: .plus, exponent: 0, significand: 1234567))
      try await __assertDecimal("-12345.67", expectedDecimal: Decimal(sign: .minus, exponent: -2, significand: 1234567))
      try await __assertDecimal("-1234567", expectedDecimal: Decimal(sign: .minus, exponent: 0, significand: 1234567))
      try await __assertDecimal("0.01234567", expectedDecimal: Decimal(sign: .plus, exponent: -8, significand: 1234567))
      try await __assertDecimal("-0.01234567", expectedDecimal: Decimal(sign: .minus, exponent: -8, significand: 1234567))
    }
  }

  func test_query_binaryResult_float() async throws {
    try await connecting {
      let result = try await $0.execute(.rawSQL("SELECT 1.23::float8"), resultFormat: .binary)
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .float8)
        XCTAssertEqual(field.value.as(Double.self), 1.23)
      }
    }
  }

  func test_query_binaryResult_int() async throws {
    try await connecting {
      let result = try await $0.execute(.select(#const(0x1234ABCD)), resultFormat: .binary)
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .int4)
        XCTAssertEqual(field.value.as(Int32.self), 0x1234ABCD)
      }
    }
  }

  func test_query_binaryResult_string() async throws {
    try await connecting {
      let result = try await $0.execute(.select(#const("STRING")), resultFormat: .binary)
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .text)
        XCTAssertEqual(field.value.as(String.self), "STRING")
      }
    }
  }

  func test_query_parameters() async throws {
    try await connecting {
      let result = try await $0.execute(
        .rawSQL("""
          SELECT
            \(#param(1)) + \(#param(2)),
            \(#param(3)) + \(#param(4)),
            \(#param(5)),
            \(#param(6)),
            \(#param(7))
          ;
        """),
        parameters: [
          Int32(1), Int32(2),
          Int64(3), Int64(4),
          true,
          try XCTUnwrap(Decimal(sqlStringValue: "0.12")),
          Data([0xDE, 0xAD, 0xBE, 0xEF]),
        ],
        resultFormat: .text
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 5) {
        let row = table[0]

        XCTAssertEqual(row[0].oid, .int4)
        XCTAssertEqual(row[0].value.as(UInt32.self), 3)

        XCTAssertEqual(row[1].oid, .int8)
        XCTAssertEqual(row[1].value.as(UInt64.self), 7)

        XCTAssertEqual(row[2].oid, .bool)
        XCTAssertEqual(row[2].value.as(Bool.self), true)

        XCTAssertEqual(row[3].oid, .numeric)
        XCTAssertEqual(row[3].value.as(Decimal.self)?.description, "0.12")

        XCTAssertEqual(row[4].oid, .bytea)
        XCTAssertEqual(row[4].value.as(Data.self), Data([0xDE, 0xAD, 0xBE, 0xEF]))
      }
    }
  }

  func test_query_simpleSelect() async throws {
    try await connecting {
      let result = try await $0.execute(.select(#const(1)))
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let row = table[0]
        let field = row[0]
        XCTAssertEqual(field.oid, .int4)
        XCTAssertEqual(field.value.as(Int32.self), 1)

        let fieldAgain = row[0]
        XCTAssertEqual(field.oid, fieldAgain.oid)
        XCTAssertEqual(field.value.as(Int32.self), fieldAgain.value.as(Int32.self))
      }
    }
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

    let connection = try newConnection(unixSocketDirectoryPath: socketDirectory)

    let connDB = await connection.database
    XCTAssertEqual(connDB, databaseName)

    let connUser = await connection.user
    XCTAssertEqual(connUser, databaseUserName)

    let connPassword = await connection.password
    XCTAssertEqual(connPassword, databasePassword)

    await connection.finish()
  }

  func test_Time() async throws {
    do { // Parser tests.
      XCTAssertEqual(
        Time("04:05:06.789"),
        Time(hour: 4, minute: 5, second: 6, microsecond: 789000)
      )
      XCTAssertEqual(
        Time("04:05:06"),
        Time(hour: 4, minute: 5, second: 6)
      )
      XCTAssertEqual(
        Time("04:05"),
        Time(hour: 4, minute: 5, second: 0)
      )
      XCTAssertEqual(
        Time("040506"),
        Time(hour: 4, minute: 5, second: 6)
      )
      XCTAssertEqual(
        Time("04:05 AM"),
        Time(hour: 4, minute: 5, second: 0)
      )
      XCTAssertEqual(
        Time("04:05 PM"),
        Time(hour: 16, minute: 5, second: 0)
      )
      XCTAssertEqual(
        Time("04:05:06.789-8"),
        Time(
          hour: 4, minute: 5, second: 6, microsecond: 789000,
          timeZone: try XCTUnwrap(TimeZone(secondsFromGMT: -8 * 3600))
        )
      )
      XCTAssertEqual(
        Time("04:05:06+09:00"),
        Time(
          hour: 4, minute: 5, second: 6,
          timeZone: try XCTUnwrap(TimeZone(secondsFromGMT: 9 * 3600))
        )
      )
      XCTAssertEqual(
        Time("04:05+09:30"),
        Time(
          hour: 4, minute: 5, second: 0,
          timeZone: try XCTUnwrap(TimeZone(secondsFromGMT: 9 * 3600 + 30 * 60))
        )
      )
      XCTAssertEqual(
        Time("040506+07:30:00"),
        Time(
          hour: 4, minute: 5, second: 6,
          timeZone: try XCTUnwrap(TimeZone(secondsFromGMT: 7 * 3600 + 30 * 60))
        )
      )
      XCTAssertEqual(
        Time("040506+07:30:00"),
        Time(
          hour: 4, minute: 5, second: 6,
          timeZone: try XCTUnwrap(TimeZone(secondsFromGMT: 7 * 3600 + 30 * 60))
        )
      )
      XCTAssertEqual(
        Time("04:05:06 PST"),
        Time(
          hour: 4, minute: 5, second: 6,
          timeZone: try XCTUnwrap(TimeZone(abbreviation: "PST"))
        )
      )
    }
  }

  func test_Timestamp() async throws {
    XCTAssertEqual(Timestamp("2000-01-01 00:00:00")?.timeIntervalSincePostgresEpoch, 0)
    XCTAssertEqual(Timestamp("2000-01-01 00:00:00+09")?.timeIntervalSincePostgresEpoch, -32400000000)
    XCTAssertEqual(Timestamp("2000-01-01 00:00:00-09")?.timeIntervalSincePostgresEpoch, +32400000000)
    XCTAssertEqual(Timestamp("1999-12-31 20:30:00-0330")?.timeIntervalSincePostgresEpoch, 0)
    #if canImport(Darwin) || canImport(FoundationEssentials) // https://github.com/apple/swift-corelibs-foundation/issues/5079
    XCTAssertEqual(Timestamp("2000-01-01 01:23:45+012345")?.timeIntervalSincePostgresEpoch, 0)
    #endif
    XCTAssertEqual(Timestamp("1970-01-01 00:00:00"), Timestamp.unixEpoch)
    XCTAssertEqual(
      Timestamp(FoundationDate(timeIntervalSinceReferenceDate: 0)),
      Timestamp("2001-01-01 00:00:00")
    )

    XCTAssertEqual(
      Timestamp("2024-09-01 12:34:56", timeZone: TimeZone(identifier: "Asia/Tokyo"))?.timeIntervalSincePostgresEpoch,
      try XCTUnwrap(Timestamp("2024-09-01 12:34:56+09")).timeIntervalSincePostgresEpoch
    )

    XCTAssertNil(Timestamp("20"))
    XCTAssertNil(Timestamp("2024-09-01 01:23:45+12345678"))

    // WITHOUT TIME ZONE
    try await connecting {
      var result = try await $0.execute(
        .select(#TIMESTAMP("2024-08-20 17:35:24")),
        resultFormat: .binary
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamp)
        XCTAssertEqual(field.value.as(Timestamp.self)?.sqlStringValue, "2024-08-20 17:35:24")
      }


      result = try await $0.execute(
        .select(#TIMESTAMP("2024-08-21 01:23:45.678901")),
        resultFormat: .text
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamp)
        XCTAssertEqual(field.value.payload?.isText, true)
        XCTAssertEqual(field.value.as(Timestamp.self)?.sqlStringValue, "2024-08-21 01:23:45.678901")
      }

      result = try await $0.execute(
        .select(#paramExpr(1)),
        parameters: [Timestamp.postgresEpoch],
        resultFormat: .binary
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamp)
        XCTAssertEqual(field.value.as(Timestamp.self)?.sqlStringValue, "2000-01-01 00:00:00")
      }
    }

    // WITH TIME ZONE
    try await connecting { (connection) -> Void in
      let dbTimeZone = await connection.timeZone

      var result = try await connection.execute(
        .select(#TIMESTAMPTZ("2024-08-26 17:04:15")),
        resultFormat: .text
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamptz)
        XCTAssertEqual(
          field.value.as(Timestamp.self, timeZone: dbTimeZone),
          Timestamp("2024-08-26 17:04:15", timeZone: dbTimeZone)
        )
      }

      result = try await connection.execute(
        .select(#TIMESTAMPTZ("2024-08-26 17:04:15")),
        resultFormat: .binary
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamptz)
        XCTAssertEqual(
          field.value.as(Timestamp.self, timeZone: dbTimeZone),
          Timestamp("2024-08-26 17:04:15", timeZone: dbTimeZone)
        )
      }

      let darwinTz = try XCTUnwrap(TimeZone(identifier: "Australia/Darwin"))
      let darwinTimestamp = try XCTUnwrap(Timestamp("2024-08-26 17:30:00", timeZone: darwinTz))
      result = try await connection.execute(
        .select(#paramExpr(1)),
        parameters: [darwinTimestamp],
        resultFormat: .text
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamptz)
        XCTAssertEqual(field.value.asTimestamp(withTimeZone: darwinTz), darwinTimestamp)
        XCTAssertEqual(
          field.value.as(Timestamp.self, timeZone: darwinTz)?.sqlStringValue,
          "2024-08-26 17:30:00+0930"
        )
      }
      result = try await connection.execute(
        .select(#paramExpr(1)),
        parameters: [darwinTimestamp],
        resultFormat: .binary
      )
      if let table = assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = table[0][0]
        XCTAssertEqual(field.oid, .timestamptz)
        XCTAssertEqual(field.value.asTimestamp(withTimeZone: darwinTz), darwinTimestamp)
      }
    }
  }

  func test_ValueConvertible() throws {
    func __assert<V, D>(
      _ value: V,
      expectedBinaryData data: D,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws where V: LosslessQueryValueConvertible, V: Equatable, D: DataProtocol {
      let queryValue = value.queryValue
      guard case .binary(let binary) = queryValue.payload else {
        XCTFail("Failed to get binary data.", file: file, line: line)
        return
      }

      let restored = try XCTUnwrap(
        V(QueryValue(oid: queryValue.oid, binary: binary)),
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
    try __assert(
      Decimal(0),
      expectedBinaryData: [
        0x00, 0x01, // nDigits
        0x00, 0x00, // weight (-1)
        0x00, 0x00, // sign
        0x00, 0x00, // dScale
        0x00, 0x00,
      ]
    )
    try __assert(
      try XCTUnwrap(Decimal(sqlStringValue: "0.12")),
      expectedBinaryData: [
        0x00, 0x01, // nDigits
        0xFF, 0xFF, // weight (-1)
        0x00, 0x00, // sign
        0x00, 0x02, // dScale
        0x04, 0xB0, // 1200
      ]
    )
    try __assert(
      try XCTUnwrap(Decimal(sqlStringValue: "12345.678")),
      expectedBinaryData: [
        0x00, 0x03, // nDigits
        0x00, 0x01, // weight (-1)
        0x00, 0x00, // sign
        0x00, 0x03, // dScale
        0x00, 0x01, // 1
        0x09, 0x29, // 2345
        0x1A, 0x7C, // 6780
      ]
    )
    try __assert(
      try XCTUnwrap(Decimal(sqlStringValue: "-987654321.0987654321")),
      expectedBinaryData: [
        0x00, 0x06, // nDigits
        0x00, 0x02, // weight (-1)
        0x40, 0x00, // sign
        0x00, 0x0A, // dScale
        0x00, 0x09, // 9
        0x22, 0x3D, // 8765
        0x10, 0xE1, // 4321
        0x03, 0xDB, // 0987
        0x19, 0x8F, // 6543
        0x08, 0x34, // 2100
      ]
    )
    try __assert("ABCD", expectedBinaryData: [0x41, 0x42, 0x43, 0x44])
  }
}
