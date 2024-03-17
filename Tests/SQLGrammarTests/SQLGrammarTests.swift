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
      AttributeList(names: [.columnLabel("label0"), .columnLabel("label1")]).description,
      ".label0.label1"
    )
  }

  func test_AnyName() {
    struct __PseudoAnyName: AnyName {
      let identifier: ColumnIdentifier
      let attributes: AttributeList?
      init(identifier: ColumnIdentifier, attributes: AttributeList? = nil) {
        self.identifier = identifier
        self.attributes = attributes
      }
    }

    XCTAssertEqual(__PseudoAnyName(identifier: "my_column").description, "my_column")
    XCTAssertEqual(
      __PseudoAnyName(
        identifier: "my_column",
        attributes: AttributeList(names: [.columnLabel("label0"), .columnLabel("label1")])
      ).description,
      "my_column.label0.label1"
    )
  }

  func test_Indirection() {
    XCTAssertEqual(
      Indirection([
        .attributeName(AttributeName(ColumnLabel("label0"))),
        .attributeName(AttributeName(ColumnLabel("label1"))),
        .any,
      ]).description,
      ".label0.label1.*"
    )
  }
}

final class SQLGrammarExpressionTests: XCTestCase {
  func test_c_expr() {
  columnref:
      do {
      XCTAssertEqual(ColumnReference(columnName: "my_column").description, "my_column")
      XCTAssertEqual(
        ColumnReference(
          tableName: TableName(schema: "public", name: "my_table"),
          columnName: "my_column"
        ).description,
        "public.my_table.my_column"
      )
    }
  AexprConst:
    do {
      XCTAssertEqual(UnsignedIntegerConstantExpression(12345).description, "12345")
      XCTAssertEqual(UnsignedFloatConstantExpression(1.2345)?.description, "1.2345")
      XCTAssertEqual(StringConstantExpression("string").description, "'string'")
      XCTAssertEqual(
        BitStringConstantExpression(try .bitString("010", style: .binary))?.description,
        "B'010'"
      )
      XCTAssertEqual(
        BitStringConstantExpression(try .bitString("1FF", style: .hexadecimal))?.description,
        "X'1FF'"
      )
    }
  }
}

final class SQLGrammarStatementTests: XCTestCase {
  func test_DropTable() {
    func __assert(
      _ dropTable: DropTable,
      _ expectedDescription: String,
      file: StaticString = #filePath, line: UInt = #line
    ) {
      XCTAssertEqual(dropTable.description, expectedDescription, file: file, line: line)
    }

    __assert(
      DropTable(
        ifExists: false,
        name: "my_table",
        behavior: nil
      ),
      "DROP TABLE my_table"
    )
    __assert(
      DropTable(
        ifExists: true,
        names: [TableName("my_table1"), TableName("my_table2")],
        behavior: .restrict
      ),
      "DROP TABLE IF EXISTS my_table1, my_table2 RESTRICT"
    )
    __assert(
      DropTable(
        names: [
          TableName(schema: "my_schema", name: "my_private_table1"),
          TableName(schema: "my_schema", name: "my_private_table2"),
        ]
      ),
      "DROP TABLE my_schema.my_private_table1, my_schema.my_private_table2"
    )
  }
}
