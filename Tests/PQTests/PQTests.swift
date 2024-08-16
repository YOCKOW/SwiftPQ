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

    func __assertTuples(
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

    SIMPLE_SELECT: do {
      let result = try await connection.execute(.select(#const(1)))
      if let table = __assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let row = table[0]
        let field = row[0]
        XCTAssertEqual(field.oid, .int4)
        XCTAssertEqual(field.value?.as(Int32.self), 1)

        let fieldAgain = row[0]
        XCTAssertEqual(field.oid, fieldAgain.oid)
        XCTAssertEqual(field.value?.as(Int32.self), fieldAgain.value?.as(Int32.self))
      }
    }

    BINARY_RESULT_TESTS: do {
      let boolResult = try await connection.execute(.select(#TRUE, #FALSE), resultFormat: .binary)
      if let boolTable = __assertTuples(boolResult, expectedNumberOfRows: 1, expectedNumberOfColumns: 2) {
        let row = boolTable[0]
        let trueField = row[0]
        let falseField = row[1]
        XCTAssertEqual(trueField.oid, .bool)
        XCTAssertEqual(falseField.oid, .bool)
        XCTAssertEqual(trueField.value?.as(Bool.self), true)
        XCTAssertEqual(falseField.value?.as(Bool.self), false)
      }

      let intResult = try await connection.execute(.select(#const(0x1234ABCD)), resultFormat: .binary)
      if let intTable = __assertTuples(intResult, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let row = intTable[0]
        let field = row[0]
        XCTAssertEqual(field.oid, .int4)
        XCTAssertEqual(field.value?.as(Int32.self), 0x1234ABCD)
      }

      let floatResult = try await connection.execute(.rawSQL("SELECT 1.23::float8"), resultFormat: .binary)
      if let floatTable = __assertTuples(floatResult, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let row = floatTable[0]
        let field = row[0]
        XCTAssertEqual(field.oid, .float8)
        XCTAssertEqual(field.value?.as(Double.self), 1.23)
      }

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
        if let decimalTable = __assertTuples(
          decimalResult,
          expectedNumberOfRows: 1,
          expectedNumberOfColumns: 1,
          file: file,
          line: line
        ) {
          let field = decimalTable[0][0]
          XCTAssertEqual(field.oid, .numeric, "Unexpected OID.", file: file, line: line)
          XCTAssertEqual(field.value?.as(Decimal.self), expectedDecimal, "Unexpected Decimal value.", file: file, line: line)
        }
      }
      try await __assertDecimal("12345.67", expectedDecimal: Decimal(sign: .plus, exponent: -2, significand: 1234567))
      try await __assertDecimal("1234567", expectedDecimal: Decimal(sign: .plus, exponent: 0, significand: 1234567))
      try await __assertDecimal("-12345.67", expectedDecimal: Decimal(sign: .minus, exponent: -2, significand: 1234567))
      try await __assertDecimal("-1234567", expectedDecimal: Decimal(sign: .minus, exponent: 0, significand: 1234567))
      try await __assertDecimal("0.01234567", expectedDecimal: Decimal(sign: .plus, exponent: -8, significand: 1234567))
      try await __assertDecimal("-0.01234567", expectedDecimal: Decimal(sign: .minus, exponent: -8, significand: 1234567))

      let strResult = try await connection.execute(.select(#const("STRING")), resultFormat: .binary)
      if let strTable = __assertTuples(strResult, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let row = strTable[0]
        let field = row[0]
        XCTAssertEqual(field.oid, .text)
        XCTAssertEqual(field.value?.as(String.self), "STRING")
      }

      let dataResult = try await connection.execute(
        .select(BinaryInfixTypeCastOperatorInvocation(#const("\\xDEADBEEF"), as: .bytea)),
        resultFormat: .binary
      )
      if let dataTable = __assertTuples(dataResult, expectedNumberOfRows: 1, expectedNumberOfColumns: 1) {
        let field = dataTable[0][0]
        XCTAssertEqual(field.oid, .bytea)
        XCTAssertEqual(field.value?.as(Data.self), Data([0xDE, 0xAD, 0xBE, 0xEF]))
      }
    }

    PARAM_TESTS: do {
      let result = try await connection.execute(
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
      if let table = __assertTuples(result, expectedNumberOfRows: 1, expectedNumberOfColumns: 5) {
        let row = table[0]

        XCTAssertEqual(row[0].oid, .int4)
        XCTAssertEqual(row[0].value?.as(UInt32.self), 3)

        XCTAssertEqual(row[1].oid, .int8)
        XCTAssertEqual(row[1].value?.as(UInt64.self), 7)

        XCTAssertEqual(row[2].oid, .bool)
        XCTAssertEqual(row[2].value?.as(Bool.self), true)

        XCTAssertEqual(row[3].oid, .numeric)
        XCTAssertEqual(row[3].value?.as(Decimal.self)?.description, "0.12")

        XCTAssertEqual(row[4].oid, .bytea)
        XCTAssertEqual(row[4].value?.as(Data.self), Data([0xDE, 0xAD, 0xBE, 0xEF]))
      }
    }

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
    ) throws where V: QueryValueConvertible, V: Equatable, D: DataProtocol {
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
