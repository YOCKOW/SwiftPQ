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

  func test_Parenthesized() {
    XCTAssertEqual(
      SingleToken(.char).followedBy(parenthesized: SingleToken(.integer(4))).description,
      "CHAR(4)"
    )
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

  func test_FunctionName() {
    XCTAssertEqual(FunctionName("my_func").description, "my_func")
    XCTAssertEqual(FunctionName(ColumnReference(tableName: "s", columnName: "f")).description, "s.f")
  }

  func test_LabeledOperator() {
    XCTAssertEqual(LabeledOperator(.minus).description, "-")
    XCTAssertEqual(LabeledOperator(schema: "pg_catalog", .plus).description, "pg_catalog.+")
  }

  func test_QualifiedOperator() throws {
    XCTAssertEqual(QualifiedOperator(try XCTUnwrap(MathOperator(.minus))).description, "-")
    XCTAssertEqual(
      QualifiedOperator(LabeledOperator(schema: "pg_catalog", .plus)).description,
      "OPERATOR(pg_catalog.+)"
    )
  }

  func test_ParamterName() {
    XCTAssertEqual(ParameterName(.identifier("my_variable"))?.description, "my_variable")
  }

  func test_FunctionArgumentList() throws {
    let list = try XCTUnwrap(FunctionArgumentList([
      nil: UnsignedIntegerConstantExpression(0),
      "parameter_name": StringConstantExpression("value"),
    ]))
    XCTAssertEqual(list.description, "0, parameter_name => 'value'")
  }

  func test_ConstantTypeName() {
    XCTAssertEqual(
      NumericTypeName.decimal(
        modifiers: GeneralExpressionList(UnsignedIntegerConstantExpression(123))
      ).description,
      "DECIMAL(123)"
    )
    XCTAssertEqual(ConstantBitStringTypeName.fixed.description, "BIT")
    XCTAssertEqual(ConstantBitStringTypeName.varying.description, "BIT VARYING")
    XCTAssertEqual(ConstantBitStringTypeName.fixed(length: 4).description, "BIT(4)")
    XCTAssertEqual(ConstantBitStringTypeName.varying(length: 4).description, "BIT VARYING(4)")
    XCTAssertEqual(ConstantCharacterTypeName.character.description, "CHARACTER")
    XCTAssertEqual(
      ConstantCharacterTypeName.character(varying: true, length: 4).description,
      "CHARACTER VARYING(4)"
    )
    XCTAssertEqual(ConstantDateTimeTypeName.timestamp.description, "TIMESTAMP")
    XCTAssertEqual(
      ConstantDateTimeTypeName.time(precision: 6, withTimeZone: true).description,
      "TIME(6) WITH TIME ZONE"
    )
  }

  func test_IntervalFieldsPhrase() {
    XCTAssertEqual(IntervalFieldsPhrase.year.description, "YEAR")
    XCTAssertEqual(IntervalFieldsPhrase.second.description, "SECOND")
    XCTAssertEqual(IntervalFieldsPhrase.second(precision: 3).description, "SECOND(3)")
    XCTAssertEqual(IntervalFieldsPhrase.hourToSecond.description, "HOUR TO SECOND")
    XCTAssertEqual(IntervalFieldsPhrase.hourToSecond(precision: 6).description, "HOUR TO SECOND(6)")
  }

  func test_TargetList() {
    XCTAssertEqual(
      TargetList([
        .init(ColumnReference(columnName: "a"), as: ColumnLabel("alias_a")),
        .init(ColumnReference(columnName: "b"), BareColumnLabel("alias_b")),
      ]).description,
      "a AS alias_a, b alias_b"
    )
  }

  func test_TemporaryTableName() {
    XCTAssertEqual(
      TemporaryTableName(table: "my_temp_table").description,
      "TEMPORARY TABLE my_temp_table"
    )
  }
}

final class SQLGrammarClauseTests: XCTestCase {
  func test_IntoCause() {
    XCTAssertEqual(
      IntoClause(.init(table: "my_temp_table")).description,
      "INTO TEMPORARY TABLE my_temp_table"
    )
  }

  func test_SortClause() throws {
    struct __PseudoAexpr: GeneralExpression {
      let ref: ColumnReference
      var tokens: ColumnReference.Tokens { ref.tokens }
    }
    let sortByExpr1 = SortBy<__PseudoAexpr>(.init(ref: "col1"))
    let sortByExpr2 = SortBy<__PseudoAexpr>(
      .init(ref: "col2"),
      direction: .descending,
      nullOrdering: .last
    )
    let sortByExpr3 = SortBy<__PseudoAexpr>(
      .init(ref: "col3"),
      using: .init(try XCTUnwrap(MathOperator(.lessThan)))
    )
    let sortClause = SortClause(sortByExpr1, sortByExpr2, sortByExpr3)
    XCTAssertEqual(
      sortClause.description,
      "ORDER BY col1, col2 DESC NULLS LAST, col3 USING <"
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
      XCTAssertEqual(UnsignedFloatConstantExpression(1.2345).description, "1.2345")
      XCTAssertEqual(StringConstantExpression("string").description, "'string'")
      XCTAssertEqual(
        BitStringConstantExpression(try .bitString("010", style: .binary))?.description,
        "B'010'"
      )
      XCTAssertEqual(
        BitStringConstantExpression(try .bitString("1FF", style: .hexadecimal))?.description,
        "X'1FF'"
      )
      XCTAssertEqual(
        GenericTypeCastStringLiteralSyntax(typeName: .init("MY_TYPE"), string: "value")?.description,
        "MY_TYPE 'value'"
      )
      XCTAssertEqual(
        GenericTypeCastStringLiteralSyntax(
          typeName: .init("MY_TYPE"),
          modifiers: .init([UnsignedIntegerConstantExpression(0).asFunctionArgument]),
          string: "value"
        )?.description,
        "MY_TYPE (0) 'value'"
      )
      XCTAssertEqual(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: .timestamp(precision: 3, withTimeZone: true),
          string: "2004-10-19 10:23:54+02"
        )?.description,
        "TIMESTAMP(3) WITH TIME ZONE '2004-10-19 10:23:54+02'"
      )
      XCTAssertEqual(
        ConstantIntervalTypeCastStringLiteralSyntax(
          string: "3 4:05:06",
          fields: .dayToSecond(precision: 3)
        )?.description,
        "INTERVAL '3 4:05:06' DAY TO SECOND(3)"
      )
      XCTAssertEqual(
        ConstantIntervalTypeCastStringLiteralSyntax(
          string: "3 4:05:06",
          precision: 6
        )?.description,
        "INTERVAL(6) '3 4:05:06'"
      )
      XCTAssertEqual(BooleanConstantExpression.true.description, "TRUE")
      XCTAssertEqual(BooleanConstantExpression.false.description, "FALSE")
      XCTAssertEqual(NullConstantExpression.null.description, "NULL")
    }
  PARAM_opt_indirection:
    do {
      XCTAssertEqual(PositionalParameterExpression(1).description, "$1")
      XCTAssertEqual(PositionalParameterExpression(2, indirection: [.any]).description, "$2.*")
    }
  lparen_aexpr_rparen_opt_indirection:
    do {
      XCTAssertEqual(
        ParenthesizedGeneralExpressionWithIndirection(
          UnsignedIntegerConstantExpression(1 as UInt),
          indirection: [.attributeName(.columnLabel("foo"))]
        ).description,
        "(1).foo"
      )
    }
  case_expr:
    do {
      XCTAssertEqual(
        CaseExpression(
          argument: ColumnReference(columnName: "a"),
          (when: UnsignedIntegerConstantExpression(1), then: StringConstantExpression("one")),
          (when: UnsignedIntegerConstantExpression(2), then: StringConstantExpression("two")),
          else: StringConstantExpression("other")
        ).description,
        "CASE a WHEN 1 THEN 'one' WHEN 2 THEN 'two' ELSE 'other' END"
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
