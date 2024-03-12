/* *************************************************************************************************
 SQLGrammarTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import NetworkGear
import XCTest
@testable import SQLGrammar

final class SQLGrammarTests: XCTestCase {
  func test_keywords() {
    XCTAssertNotNil(SQLToken.keyword(from: "CREATE"))
    XCTAssertNotNil(SQLToken.keyword(from: "Drop"))
    XCTAssertNotNil(SQLToken.keyword(from: "none"))
    XCTAssertNil(SQLToken.keyword(from: "hogehoge"))
  }

  func test_JoinedSQLTokenSequence() {
    var tokens: [SQLToken] = []
    XCTAssertEqual(tokens.joined().description, "")
    XCTAssertEqual(tokens.joinedByCommas().description, "")

    tokens = [.integer(0)]
    XCTAssertEqual(tokens.joined().description, "0")
    XCTAssertEqual(tokens.joinedByCommas().description, "0")

    tokens.append(contentsOf: [.integer(1), .integer(2)])
    XCTAssertEqual(tokens.joined().description, "0 1 2")
    XCTAssertEqual(tokens.joinedByCommas().description, "0, 1, 2")
  }

  func test_TerminatedStatement() {
    struct __PseudoStatement: Statement {
      let tokens: [SQLToken] = [.drop, .table, .identifier("my_table")]
    }
    let statement = __PseudoStatement()
    XCTAssertEqual(statement.description, "DROP TABLE my_table")
    XCTAssertEqual(statement.terminated.description, "DROP TABLE my_table;")
  }

  func test_ColumnIdentifier() {
    XCTAssertNotNil(ColumnIdentifier(.identifier("my_column")))
    XCTAssertNotNil(ColumnIdentifier(.xml))
    XCTAssertNotNil(ColumnIdentifier(.identifier("DO")))
    XCTAssertNil(ColumnIdentifier(.do))
  }

  func test_Attributes() {
    XCTAssertEqual(
      Attributes(names: [.columnLabel("label0"), .columnLabel("label1")]).description,
      ".label0.label1"
    )
  }

  func test_AnyName() {
    XCTAssertEqual(AnyName(columnIdentifier: "my_column").description, "my_column")
    XCTAssertEqual(
      AnyName(
        columnIdentifier: "my_column",
        attributes: Attributes(names: [.columnLabel("label0"), .columnLabel("label1")])
      ).description,
      "my_column.label0.label1"
    )
  }
}
