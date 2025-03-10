/* *************************************************************************************************
 SQLGrammarTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import NetworkGear
@testable import SQLGrammar

#if swift(>=6) && canImport(Testing)
import Testing
#else
import XCTest
#endif

func assertDescription<T>(
  _ tokens: T, _ expectedDescription: String,
  _ message: @autoclosure () -> String = "",
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) where T: TokenSequenceGenerator {
  #if swift(>=6) && canImport(Testing)
  #expect(
    tokens.description == expectedDescription,
    Comment(rawValue: message()),
    sourceLocation: SourceLocation(
      fileID: String(describing: fileID),
      filePath: String(describing: filePath),
      line: Int(line),
      column: Int(column)
    )
  )
  #else
  XCTAssertEqual(tokens.description, expectedDescription, message(), file: filePath, line: line)
  #endif
}

#if swift(>=6) && canImport(Testing)
@Suite final class SQLGrammarTests {
  @Test func test_keywords() {
    #expect(Token.keyword(from: "CREATE") != nil)
    #expect(Token.keyword(from: "Drop") != nil)
    #expect(Token.keyword(from: "none") != nil)
    #expect(Token.keyword(from: "hogehoge") == nil)
  }

  @Test func test_JoinedSQLTokenSequence() {
    var tokens: [Token] = []
    #expect(tokens.joined().description == "")
    #expect(tokens.joinedByCommas().description == "")

    tokens = [.integer(0)]
    #expect(tokens.joined().description == "0")
    #expect(tokens.joinedByCommas().description == "0")

    tokens.append(contentsOf: [.integer(1), .integer(2)])
    #expect(tokens.joined().description == "0 1 2")
    #expect(tokens.joinedByCommas().description == "0, 1, 2")
  }

  @Test func test_Parenthesized() {
    #expect(
      SingleToken(.char).followedBy(parenthesized: SingleToken(.integer(4))).description ==
      "CHAR(4)"
    )
  }

  @Test func test_ColumnIdentifier() {
    #expect(ColumnIdentifier(.identifier("my_column")) != nil)
    #expect(ColumnIdentifier(.xml) != nil)
    #expect(ColumnIdentifier(.identifier("DO")) != nil)
    #expect(ColumnIdentifier(.do) == nil)
  }

  @Test func test_Attributes() {
    #expect(
      AttributeList(names: [.columnLabel("label0"), .columnLabel("label1")]).description ==
      ".label0.label1"
    )
  }

  @Test func test_AnyName() {
    struct __PseudoAnyName: AnyName {
      let identifier: ColumnIdentifier
      let attributes: AttributeList?
      init(identifier: ColumnIdentifier, attributes: AttributeList? = nil) {
        self.identifier = identifier
        self.attributes = attributes
      }
    }

    #expect(__PseudoAnyName(identifier: "my_column").description == "my_column")
    #expect(
      __PseudoAnyName(
        identifier: "my_column",
        attributes: AttributeList(names: [.columnLabel("label0"), .columnLabel("label1")])
      ).description == "my_column.label0.label1"
    )
  }

  @Test func test_Indirection() {
    #expect(
      Indirection([
        .attributeName(AttributeName(ColumnLabel("label0"))),
        .attributeName(AttributeName(ColumnLabel("label1"))),
        .any,
      ]).description == ".label0.label1.*"
    )
  }

  @Test func test_FunctionApplication() {
    assertDescription(FunctionApplication(FunctionName("f"), arguments: nil), "f()")
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        arguments: FunctionArgumentList([UnsignedIntegerConstantExpression(0).asFunctionArgument])
      ),
      "f(0)"
    )
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        variadicArgument: UnsignedIntegerConstantExpression(0).asFunctionArgument,
        orderBy: SortClause(SortBy(ColumnReference(columnName: "col1")))
      ),
      "f(VARIADIC 0 ORDER BY col1)"
    )
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        arguments: FunctionArgumentList([UnsignedIntegerConstantExpression(0).asFunctionArgument]),
        variadicArgument: UnsignedIntegerConstantExpression(1).asFunctionArgument
      ),
      "f(0, VARIADIC 1)"
    )
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        aggregate: .distinct,
        arguments: FunctionArgumentList([
          UnsignedIntegerConstantExpression(0).asFunctionArgument,
          UnsignedIntegerConstantExpression(1).asFunctionArgument
        ])
      ),
      "f(DISTINCT 0, 1)"
    )
    assertDescription(FunctionApplication(FunctionName("f"), arguments: .any), "f(*)")
  }

  @Test func test_FunctionName() {
    #expect(FunctionName("my_func").description == "my_func")
    #expect(FunctionName(ColumnReference(tableName: "s", columnName: "f")).description == "s.f")
  }

  @Test func test_FunctionType() throws {
    assertDescription(
      FunctionType(
        copyingType: try #require(CopyingTypeColumnReference(table: "users", column: "user_id"))
      ),
      "users.user_id%TYPE"
    )
  }

  @Test func test_LabeledOperator() {
    #expect(LabeledOperator(.minus).description == "-")
    #expect(LabeledOperator(schema: "pg_catalog", .plus).description == "pg_catalog.+")
  }

  @Test func test_QualifiedOperator() throws {
    #expect(QualifiedOperator(try #require(MathOperator(.minus))).description == "-")
    #expect(
      QualifiedOperator(LabeledOperator(schema: "pg_catalog", .plus)).description ==
      "OPERATOR(pg_catalog.+)"
    )
  }

  @Test func test_ParamterName() {
    #expect(ParameterName(.identifier("my_variable"))?.description == "my_variable")
  }

  @Test func test_FunctionArgumentList() throws {
    let list = try #require(FunctionArgumentList([
      nil: UnsignedIntegerConstantExpression(0),
      "parameter_name": StringConstantExpression("value"),
    ]))
    #expect(list.description == "0, parameter_name => 'value'")
  }

  @Test func test_ConstantTypeName() {
    #expect(
      NumericTypeName.decimal(
        modifiers: GeneralExpressionList(UnsignedIntegerConstantExpression(123))
      ).description == "DECIMAL(123)"
    )
    #expect(ConstantBitStringTypeName.fixed.description == "BIT")
    #expect(ConstantBitStringTypeName.varying.description == "BIT VARYING")
    #expect(ConstantBitStringTypeName.fixed(length: 4).description == "BIT(4)")
    #expect(ConstantBitStringTypeName.varying(length: 4).description == "BIT VARYING(4)")
    #expect(ConstantCharacterTypeName.character.description == "CHARACTER")
    #expect(
      ConstantCharacterTypeName.character(varying: true, length: 4).description ==
      "CHARACTER VARYING(4)"
    )
    #expect(ConstantDateTimeTypeName.timestamp.description == "TIMESTAMP")
    #expect(
      ConstantDateTimeTypeName.time(precision: 6, withTimeZone: true).description ==
      "TIME(6) WITH TIME ZONE"
    )
  }

  @Test func test_IntervalFieldsPhrase() {
    #expect(IntervalFieldsPhrase.year.description == "YEAR")
    #expect(IntervalFieldsPhrase.second.description == "SECOND")
    #expect(IntervalFieldsPhrase.second(precision: 3).description == "SECOND(3)")
    #expect(IntervalFieldsPhrase.hourToSecond.description == "HOUR TO SECOND")
    #expect(IntervalFieldsPhrase.hourToSecond(precision: 6).description == "HOUR TO SECOND(6)")
  }

  @Test func test_TargetList() {
    #expect(
      TargetList([
        .init(ColumnReference(columnName: "a"), as: ColumnLabel("alias_a")),
        .init(ColumnReference(columnName: "b"), BareColumnLabel("alias_b")),
      ]).description == "a AS alias_a, b alias_b"
    )
  }

  @Test func test_TemporaryTableName() {
    #expect(
      TemporaryTableName(table: "my_temp_table").description ==
      "TEMPORARY TABLE my_temp_table"
    )
  }

  @Test func test_TypeName() {
    assertDescription(
      TypeName(NumericTypeName.int, arrayModifier: .oneDimensionalArray(size: 3)),
      "INT ARRAY[3]"
    )
    assertDescription(
      TypeName(CharacterTypeName.char, arrayModifier: .multipleDimensionalArray([nil, 3])),
      "CHAR[][3]"
    )
  }

  @Test func test_TableFunction() {
    assertDescription(
      TableFunction(functionCall: CurrentDate.currentDate, withOrdinality: true),
      "CURRENT_DATE WITH ORDINALITY"
    )
    assertDescription(
      TableFunction(
        rowsFrom: TableFunction.RowsFromSyntax([
          TableFunction.RowsFromSyntax.Item(
            functionCall: CurrentUser.currentUser,
            columnDefinitions: [
              TableFunctionElement(column: "col1", type: TypeName(GenericTypeName.text))
            ]
          )
        ])
      ),
      "ROWS FROM(CURRENT_USER AS (col1 TEXT))"
    )
  }

  @Test func test_OnCommitOption() {
    assertDescription(OnCommitOption.drop, "ON COMMIT DROP")
    assertDescription(OnCommitOption.deleteRows, "ON COMMIT DELETE ROWS")
  }

  @Test func test_TableSpaceSpecifier() {
    assertDescription(TableSpaceSpecifier("myTableSpace"), "TABLESPACE myTableSpace")
  }

  @Test func test_TableConstraint() {
  ELEMENTS:
    do {
      assertDescription(
        TableConstraintElement.check(
          BinaryInfixNotEqualToOperatorInvocation(
            ColumnReference(columnName: "myColumn"),
            UnsignedIntegerConstantExpression(100)
          ),
          noInherit: true,
          deferrable: .deferrable,
          checkConstraint: .initiallyImmediate
        ),
        "CHECK (myColumn <> 100) NO INHERIT DEFERRABLE INITIALLY IMMEDIATE"
      )
      assertDescription(
        TableConstraintElement.unique(
          nulls: .notDistinct,
          columns: ["col1", "col2"],
          include: .init(columns: ["col3", "col4"]),
          with: .init(["someKey": 0]),
          tableSpace: .init("myTableSpace"),
          deferrable: .notDeferrable,
          checkConstraint: .initiallyDeferred
        ),
        "UNIQUE NULLS NOT DISTINCT (col1, col2) INCLUDE (col3, col4) " +
        "WITH (someKey = 0) USING INDEX TABLESPACE myTableSpace " +
        "NOT DEFERRABLE INITIALLY DEFERRED"
      )
      assertDescription(
        TableConstraintElement.primaryKey(
          columns: ["col1", "col2"],
          include: .init(columns: ["col3", "col4"]),
          with: .init(["someKey": 1.2])
        ),
        "PRIMARY KEY (col1, col2) INCLUDE (col3, col4) WITH (someKey = 1.2)"
      )
      assertDescription(
        TableConstraintElement.exclude(
          using: .init(methodName: "myMethod"),
          elements: [
            ExclusionConstraintElement(
              IndexElement(columnName: "foo"),
              with: LabeledOperator(Token.Operator.lessThan)
            ),
            ExclusionConstraintElement(
              IndexElement(columnName: "bar"),
              with: LabeledOperator(Token.Operator.greaterThan)
            ),
          ],
          where: .init(predicate: BinaryInfixGreaterThanOperatorInvocation(
            ColumnReference("hoge"),
            UnsignedIntegerConstantExpression(0)
          ))
        ),
        "EXCLUDE USING myMethod (foo WITH <, bar WITH >) WHERE (hoge > 0)"
      )
      assertDescription(
        TableConstraintElement.foreignKey(
          columns: ["col1", "col2"],
          referenceTable: "refTable",
          referenceColumns: ["refCol1", "refCol2"],
          match: .full,
          actions: .init(onDelete: .cascade, onUpdate: .noAction)
        ),
        "FOREIGN KEY (col1, col2) REFERENCES refTable (refCol1, refCol2) MATCH FULL " +
        "ON DELETE CASCADE ON UPDATE NO ACTION"
      )
    }
  CONSTRAINTS:
    do {
      assertDescription(
        TableConstraint(name: "myConstraint", constraint: .unique(columns: ["col1"])),
        "CONSTRAINT myConstraint UNIQUE (col1)"
      )
    }
  }

  @Test func test_ColumnConstraintElement() {
    assertDescription(ColumnConstraintElement.notNull, "NOT NULL")
    assertDescription(ColumnConstraintElement.null,  "NULL")
    assertDescription(
      ColumnConstraintElement.unique(
        nulls: .distinct,
        with: .init(["someKey": 0]),
        tableSpace: .init("myTableSpace")
      ),
      "UNIQUE NULLS DISTINCT WITH (someKey = 0) USING INDEX TABLESPACE myTableSpace"
    )
    assertDescription(ColumnConstraintElement.unique,  "UNIQUE")
    assertDescription(
      ColumnConstraintElement.primaryKey(
        with: .init(["someKey": 0]),
        tableSpace: .init("myTableSpace")
      ),
      "PRIMARY KEY WITH (someKey = 0) USING INDEX TABLESPACE myTableSpace"
    )
    assertDescription(ColumnConstraintElement.primaryKey, "PRIMARY KEY")
    assertDescription(
      ColumnConstraintElement.check(
        BinaryInfixGreaterThanOperatorInvocation(
          ColumnReference(columnName: "myCol"),
          UnsignedIntegerConstantExpression(0)
        ),
        noInherit: true
      ),
      "CHECK (myCol > 0) NO INHERIT"
    )
    assertDescription(
      ColumnConstraintElement.default(UnsignedFloatConstantExpression(1.2)),
      "DEFAULT 1.2"
    )
    assertDescription(
      ColumnConstraintElement.generatedAsIdentity(.always, sequenceOptions: [.cycle, .ownedByNone]),
      "GENERATED ALWAYS AS IDENTITY (CYCLE OWNED BY NONE)"
    )
    assertDescription(
      ColumnConstraintElement.generatedStoredValue(
        from: BinaryInfixPlusOperatorInvocation(
          ColumnReference(columnName: "otherCol"),
          UnsignedIntegerConstantExpression(1)
        )
      ),
      "GENERATED ALWAYS AS (otherCol + 1) STORED"
    )
    assertDescription(
      ColumnConstraintElement.references(
        referenceTable: "refTable",
        referenceColumns: ["refCol1", "refCol2"],
        match: .full,
        actions: .init(onDelete: .setNull, onUpdate: .noAction)
      ),
      "REFERENCES refTable (refCol1, refCol2) MATCH FULL ON DELETE SET NULL ON UPDATE NO ACTION"
    )
  }

  @Test func test_ColumnQualifier() {
    assertDescription(
      ColumnQualifier.constraint(name: "myConstraint", element: .primaryKey),
      "CONSTRAINT myConstraint PRIMARY KEY"
    )
    assertDescription(ColumnQualifier.attribute(.deferrable), "DEFERRABLE")
    assertDescription(ColumnQualifier.collation(.c), "COLLATE \"C\"")
  }

  @Test func test_ColumnQualifierList() {
    assertDescription(
      ColumnQualifierList(
        collation: .locale(Locale(identifier: "ja-JP")),
        constraints: [
          .init(
            .primaryKey,
            deferrable: .notDeferrable,
            checkConstraint: .initiallyImmediate
          )
        ]
      ),
      #"COLLATE "ja_JP" PRIMARY KEY NOT DEFERRABLE INITIALLY IMMEDIATE"#
    )
  }

  @Test func test_ColumnDefinition() {
    assertDescription(ColumnDefinition(name: "prodDate", dataType: .date), "prodDate DATE")
    assertDescription(
      ColumnDefinition(
        name: "title",
        dataType: .varchar(40),
        qualifiers: .constraints([.init(.notNull)])
      ),
      "title VARCHAR(40) NOT NULL"
    )
    assertDescription(
      ColumnDefinition(
        name: "code",
        dataType: .char(5),
        qualifiers: .constraints([
          .init(NamedColumnConstraint(name: "firstKey", element: .primaryKey))
        ])
      ),
      "code CHAR(5) CONSTRAINT firstKey PRIMARY KEY"
    )
  }

  @Test func test_TypedTableColumnDefinition() {
    assertDescription(
      TypedTableColumnDefinition(
        name: "salary",
        withOptions: [.init(.default(UnsignedIntegerConstantExpression(1000)))]
      ),
      "salary WITH OPTIONS DEFAULT 1000"
    )
  }

  @Test func test_TableElement() {
    assertDescription(
      TableElementList([
        ColumnDefinition(name: "myCol", dataType: .int),
        TableConstraint(
          constraint: .check(
            BinaryInfixGreaterThanOperatorInvocation(
              ColumnReference(stringLiteral: "myCol"),
              UnsignedIntegerConstantExpression(0)
            )
          )
        )
      ]),
      "myCol INT, CHECK (myCol > 0)"
    )
    assertDescription(
      OptionalTypedTableElementList([
        TypedTableColumnDefinition(name: "myCol"),
        TableConstraint(
          constraint: .check(
            BinaryInfixGreaterThanOperatorInvocation(
              ColumnReference(stringLiteral: "myCol"),
              UnsignedIntegerConstantExpression(0)
            )
          )
        )
      ]),
      "(myCol, CHECK (myCol > 0))"
    )
  }

  @Test func test_RawParseMode() {
    assertDescription(
      RawParseMode.default([DropTableStatement(name: "myOldTable")]),
      "DROP TABLE myOldTable"
    )
    assertDescription(RawParseMode.typeName(.int), "MODE_TYPE_NAME INT")
    assertDescription(
      RawParseMode.plpgSQLExpression(.init(allOrDistinct: .all)),
      "MODE_PLPGSQL_EXPR ALL"
    )
    assertDescription(
      RawParseMode.plpgSQLAssignment1(
        .init(
          variable: .init(Token.PositionalParameter(1)),
          operator: .equalTo,
          expression: .init(targets: [.all])
        )
      ),
      "MODE_PLPGSQL_ASSIGN1 $1 = *"
    )
  }
}

@Suite final class SQLGrammarClauseTests {
  @Test func test_AliasClause() {
    assertDescription(AliasClause(alias: "foo"), "AS foo")
    assertDescription(AliasClause(alias: "foo", columnAliases: ["bar", "baz"]), "AS foo (bar, baz)")
  }

  @Test func test_CollateClause() {
    assertDescription(
      CollateClause(name: .c),
      #"COLLATE "C""#
    )
  }

  @Test func test_ConstraintTableSpaceClause() {
    assertDescription(
      ConstraintTableSpaceClause("myTableSpace"),
      "USING INDEX TABLESPACE myTableSpace"
    )
  }

  @Test func test_CycleClause() {
    assertDescription(
      CycleClause(
        ["id"],
        set: "is_cycle",
        to: UnsignedIntegerConstantExpression(1),
        default: UnsignedIntegerConstantExpression(0),
        using: "path"
      ),
      "CYCLE id SET is_cycle TO 1 DEFAULT 0 USING path"
    )
  }

  @Test func test_DistinctClause() {
    assertDescription(DistinctClause(expressions: nil), "DISTINCT")
    assertDescription(
      DistinctClause(expressions: [
        ColumnReference(columnName: "col1"),
        ColumnReference(columnName: "col2"),
      ]),
      "DISTINCT ON (col1, col2)"
    )
  }

  @Test func test_FunctionAliasClause() {
    assertDescription(
      FunctionAliasClause(
        alias: "myAlias",
        columnAliases: ["colAlias1"]
      ),
      "AS myAlias (colAlias1)"
    )
    assertDescription(
      FunctionAliasClause(
        alias: "myAlias",
        columnDefinitions: [
          TableFunctionElement(column: "myCol1", type: TypeName(GenericTypeName.text))
        ]
      ),
      "AS myAlias (myCol1 TEXT)"
    )
  }

  @Test func test_GroupClause() {
    assertDescription(
      GroupClause(columnReferences: [
        .expression(ColumnReference(columnName: "a")),
        .cube(CubeClause([
          ColumnReference(columnName: "b"),
          ColumnReference(columnName: "c"),
        ])),
        .groupingSets(GroupingSetsClause([
          GroupingElement(
            ParenthesizedGeneralExpressionWithIndirection(ColumnReference(columnName: "d"))
          ),
          GroupingElement(
            ParenthesizedGeneralExpressionWithIndirection(ColumnReference(columnName: "e"))
          ),
        ]))
      ]),
      "GROUP BY a, CUBE(b, c), GROUPING SETS((d), (e))"
    )
  }

  @Test func test_HavingClause() {
    assertDescription(HavingClause(predicate: BooleanConstantExpression.true), "HAVING TRUE")
  }

  @Test func test_InheritClause() {
    assertDescription(InheritClause(["mother", "father"]), "INHERITS (mother, father)")
  }

  @Test func test_IntoClause() {
    assertDescription(
      IntoClause(.init(table: "my_temp_table")),
      "INTO TEMPORARY TABLE my_temp_table"
    )
  }

  @Test func test_LockingClause() {
    assertDescription(LockingClause.forReadOnly, "FOR READ ONLY")
    assertDescription(
      LockingClause(LockingMode(for: .update, of: ["tableName1"], waitOption: .noWait)),
      "FOR UPDATE OF tableName1 NOWAIT"
    )
    assertDescription(
      LockingClause(LockingMode(for: .keyShare, of: ["tableName1"], waitOption: .skip)),
      "FOR KEY SHARE OF tableName1 SKIP LOCKED"
    )
  }

  @Test func test_PartitionSpecification() {
    assertDescription(
      PartitionSpecification(
        strategy: .range,
        parameters: [.init(columnName: "col1"), .init(columnName: "col2")]
      ),
      "PARTITION BY RANGE (col1, col2)"
    )
    assertDescription(
      PartitionSpecification(
        strategy: .hash,
        parameters: [.init(columnName: "col1"), .init(columnName: "col2")]
      ),
      "PARTITION BY HASH (col1, col2)"
    )
  }

  @Test func test_SearchClause() {
    assertDescription(
      SearchClause(.breadthFirst, by: ["id"], set: "orderCol"),
      "SEARCH BREADTH FIRST BY id SET orderCol"
    )
  }

  @Test func test_SelectClause() {
    assertDescription(
      SelectClause(ValuesClause([
        [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
      ])),
      "VALUES (1, 'one')"
    )
  }

  @Test func test_SelectLimitClause() {
    assertDescription(
      SelectLimitClause.limit(count: SelectLimitValue(10), offset: SelectOffsetValue(2)),
      "LIMIT 10 OFFSET 2"
    )
    assertDescription(
      SelectLimitClause.offset(
        .init(UnsignedIntegerConstantExpression(2)),
        .rows,
        fetch: .next,
        .init(UnsignedIntegerConstantExpression(10)),
        .rows,
        option: .withTies
      ),
      "OFFSET 2 ROWS FETCH NEXT 10 ROWS WITH TIES"
    )
  }

  @Test func test_SortClause() throws {
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
      using: .init(try #require(MathOperator(.lessThan)))
    )
    let sortClause = SortClause(sortByExpr1, sortByExpr2, sortByExpr3)
    assertDescription(
      sortClause,
      "ORDER BY col1, col2 DESC NULLS LAST, col3 USING <"
    )
  }

  @Test func test_TableAccessMethodClause() {
    assertDescription(TableAccessMethodClause(methodName: "myMethod"), "USING myMethod")
  }

  @Test func test_TableSampleClause() {
    assertDescription(
      TableSampleClause(
        samplingMethod: FunctionName("sampling"),
        arguments: .init(BooleanConstantExpression.true)
      ),
      "TABLESAMPLE sampling(TRUE)"
    )
    assertDescription(
      TableSampleClause(
        samplingMethod: FunctionName("sampling"),
        arguments: .init(BooleanConstantExpression.false),
        repeatable: RepeatableClause<UnsignedIntegerConstantExpression>(seed: 1)
      ),
      "TABLESAMPLE sampling(FALSE) REPEATABLE(1)"
    )
  }

  @Test func test_ValuesClause() {
    assertDescription(
      ValuesClause([
        [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
        [UnsignedIntegerConstantExpression(2), StringConstantExpression("two")],
        [UnsignedIntegerConstantExpression(3), StringConstantExpression("three")],
      ]),
      "VALUES (1, 'one'), (2, 'two'), (3, 'three')"
    )
  }

  @Test func test_WhereClause() {
    assertDescription(WhereClause(condition: BooleanConstantExpression.true), "WHERE TRUE")
  }

  @Test func test_WithClause() {
    assertDescription(
      WithClause(
        recursive: true,
        queries: [
          CommonTableExpression(
            name: "withName",
            columnNames: nil,
            subquery: ValuesClause([[UnsignedIntegerConstantExpression(0)]])
          )
        ]
      ),
      "WITH RECURSIVE withName AS (VALUES (0))"
    )
  }

  @Test func test_WithStorageParametersClause() {
    assertDescription(
      WithStorageParametersClause([
        .fillfactor: 50,
        .parallelWorkers: 4,
      ]),
      "WITH (fillfactor = 50, parallel_workers = 4)"
    )
    assertDescription(WithStorageParametersClause.withoutOIDs, "WITHOUT OIDS")
  }

  @Test func test_WindowClause() {
    assertDescription(
      WindowClause([
        WindowDefinition(
          name: "winName",
          specification: WindowSpecification(
            name: nil,
            partitionBy: nil,
            orderBy: SortClause(SortBy(BooleanConstantExpression.true)),
            frame: nil
          )
        )
      ]),
      "WINDOW winName AS (ORDER BY TRUE)"
    )
  }
}

@Suite final class SQLGrammarExpressionTests {
  @Test func test_AggregateWindowFunction() {
    assertDescription(
      AggregateWindowFunction(
        application: FunctionApplication(
          "myAggFunc",
          arguments: FunctionArgumentList([
            FunctionArgumentExpression(StringConstantExpression("arg"))
          ])
        ),
        withinGroup: WithinGroupClause(
          orderBy: SortClause(SortBy<ColumnReference>(ColumnReference(columnName: "col1")))
        )
      ),
      "myAggFunc('arg') WITHIN GROUP(ORDER BY col1)"
    )
    assertDescription(
      AggregateWindowFunction(
        application: FunctionApplication(
          "myFunc",
          arguments: FunctionArgumentList([
            FunctionArgumentExpression(StringConstantExpression("arg"))
          ]),
          orderBy: SortClause(SortBy<ColumnReference>(ColumnReference(columnName: "col1")))
        ),
        filter: FilterClause(where: BooleanConstantExpression.true),
        window: OverClause(windowSpecification: WindowSpecification(
          name: "myWindow",
          partitionBy: PartitionClause(.init([ColumnReference(columnName: "myPart")])),
          orderBy: nil,
          frame: FrameClause(
            mode: .range,
            extent: .init(start: .unboundedPreceding, end: .currentRow),
            exclusion: .excludeNoOthers
          )
        ))
      ),
      "myFunc('arg' ORDER BY col1) FILTER(WHERE TRUE) OVER (myWindow PARTITION BY myPart RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS)"
    )
  }

  @Test func test_CoalesceFunction() {
    assertDescription(
      CoalesceFunction([
        ColumnReference(columnName: "foo"),
        ColumnReference(columnName: "bar"),
        StringConstantExpression("Hello"),
      ]),
      "COALESCE(foo, bar, 'Hello')"
    )
  }

  @Test func test_CommonTableExpression() {
    assertDescription(
      CommonTableExpression(
        name: "withName",
        columnNames: ["col1", "col2"],
        materialized: .notMaterialized,
        subquery: ValuesClause([
          [UnsignedIntegerConstantExpression(0), StringConstantExpression("zero")],
          [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
        ]),
        search: SearchClause(.breadthFirst, by: ["col1"], set: "orderCol"),
        cycle: CycleClause(["col1"], set: "isCycle", using: "path")
      ),
      "withName(col1, col2) AS NOT MATERIALIZED (VALUES (0, 'zero'), (1, 'one')) " +
      "SEARCH BREADTH FIRST BY col1 SET orderCol " +
      "CYCLE col1 SET isCycle USING path"
    )

    assertDescription(
      CommonTableExpressionList([
        CommonTableExpression(
          name: "withName1",
          columnNames: nil,
          subquery: ValuesClause([[UnsignedIntegerConstantExpression(1)]])
        ),
        CommonTableExpression(
          name: "withName2",
          columnNames: nil,
          subquery: ValuesClause([[UnsignedIntegerConstantExpression(2)]])
        ),
      ]),
      "withName1 AS (VALUES (1)), withName2 AS (VALUES (2))"
    )
  }

  @Test func test_CurrentTime() {
    assertDescription(CurrentTime(), "CURRENT_TIME")
    assertDescription(CurrentTime(precision: 6), "CURRENT_TIME(6)")
  }

  @Test func test_ExtractFunction() throws {
    assertDescription(
      ExtractFunction(
        field: .day,
        from: try #require(ConstantTypeCastStringLiteralSyntax(
          constantTypeName: ConstantDateTimeTypeName.timestamp,
          string: "2024-05-13 16:29:55"
        ))
      ),
      "EXTRACT(DAY FROM TIMESTAMP '2024-05-13 16:29:55')"
    )
  }

  @Test func test_JSONAggregateWindowFunction() {
    assertDescription(
      JSONAggregateWindowFunction(
        JSONArrayAggregateFunction(
          value: JSONValueExpression(value: StringConstantExpression("foo"))
        ),
        filter: FilterClause(where: BooleanConstantExpression.true),
        window: .init(windowName: "myWindow")
      ),
      "JSON_ARRAYAGG('foo') FILTER(WHERE TRUE) OVER myWindow"
    )
  }

  @Test func test_JSONArrayAggregateFunction() {
    assertDescription(
      JSONArrayAggregateFunction(
        value: JSONValueExpression(value: UnsignedIntegerConstantExpression(1)),
        orderBy: JSONArrayAggregateSortClause(SortBy(ColumnReference(columnName: "col1"))),
        nullOption: .nullOnNull,
        outputType: JSONOutputTypeClause(typeName: TypeName(GenericTypeName.json))
      ),
      "JSON_ARRAYAGG(1 ORDER BY col1 NULL ON NULL RETURNING JSON)"
    )
  }

  @Test func test_JSONArrayFunction() {
    assertDescription(
      JSONArrayFunction(
        values: JSONValueExpressionList(values: [
          JSONValueExpression(value: StringConstantExpression("string")),
          JSONValueExpression(value: UnsignedIntegerConstantExpression(1)),
        ]),
        nullOption: .absentOnNull,
        outputType: .init(typeName: TypeName(GenericTypeName.text))
      ),
      "JSON_ARRAY('string', 1 ABSENT ON NULL RETURNING TEXT)"
    )
  }

  @Test func test_JSONObjectAggregateFunction() {
    assertDescription(
      JSONObjectAggregateFunction(
        keyValuePair: JSONKeyValuePair(
          key: StringConstantExpression("key"),
          value: JSONValueExpression(value: StringConstantExpression("value"))
        ),
        nullOption: .absentOnNull,
        keyUniquenessOption: .withoutUniqueKeys,
        outputType: JSONOutputTypeClause(typeName: TypeName(GenericTypeName.json))
      ),
      "JSON_OBJECTAGG('key' : 'value' ABSENT ON NULL WITHOUT UNIQUE KEYS RETURNING JSON)"
    )
  }

  @Test func test_JSONObjectFunction() {
    assertDescription(
      JSONObjectFunction(
        keyValuePairs: [
          StringConstantExpression("key"): JSONValueExpression(value: StringConstantExpression("value")),
        ],
        nullOption: .nullOnNull,
        keyUniquenessOption: .withUniqueKeys,
        outputType: JSONOutputTypeClause(
          typeName: TypeName(GenericTypeName.text),
          format: JSONFormatClause(encoding: JSONEncodingClause.utf8)
        )
      ),
      "JSON_OBJECT('key' : 'value' NULL ON NULL WITH UNIQUE KEYS RETURNING TEXT FORMAT JSON ENCODING UTF8)"
    )
  }

  @Test func test_NormalizeFunction() {
    assertDescription(
      NormalizeFunction(text: StringConstantExpression("text")),
      "NORMALIZE('text')"
    )
    assertDescription(
      NormalizeFunction(text: StringConstantExpression("text"), form: .nfc),
      "NORMALIZE('text', NFC)"
    )
  }

  @Test func test_NullIfFunction() {
    assertDescription(
      NullIfFunction(ColumnReference(columnName: "someValue"), StringConstantExpression("foo")),
      "NULLIF(someValue, 'foo')"
    )
  }

  @Test func test_OverlayFunction() {
    assertDescription(
      OverlayFunction(
        targetText: StringConstantExpression("Txxxxas"),
        replacementText: StringConstantExpression("hom"),
        startIndex: UnsignedIntegerConstantExpression(2),
        length: UnsignedIntegerConstantExpression(4)
      ),
      "OVERLAY('Txxxxas' PLACING 'hom' FROM 2 FOR 4)"
    )
  }

  @Test func test_PositionFunction() {
    assertDescription(
      PositionFunction(StringConstantExpression("yo"), in: StringConstantExpression("yockow")),
      "POSITION('yo' IN 'yockow')"
    )
  }

  @Test func test_RelationExpression() {
    assertDescription(
      RelationExpression(TableName(schema: "my_schema", name: "my_table")),
      "my_schema.my_table"
    )
    assertDescription(
      RelationExpression(
        TableName(schema: "my_schema", name: "my_table"),
        includeDescendantTables: true
      ),
      "my_schema.my_table *"
    )
    assertDescription(
      RelationExpression(
        TableName(schema: "my_schema", name: "my_table"),
        includeDescendantTables: false
      ),
      "ONLY my_schema.my_table"
    )
  }

  @Test func test_RowExpression() {
    assertDescription(
      RowExpression(fields: [
        UnsignedIntegerConstantExpression(0),
        UnsignedFloatConstantExpression(1.2),
        StringConstantExpression("string"),
      ]),
      "(0, 1.2, 'string')"
    )
    assertDescription(
      RowExpression(fields: [
        UnsignedIntegerConstantExpression(0),
      ]),
      "ROW(0)"
    )
    assertDescription(RowExpression(), "ROW()")
  }

  @Test func test_SubstringFunction() {
    assertDescription(
      SubstringFunction(
        targetText: StringConstantExpression("YOCKOW"),
        from: UnsignedIntegerConstantExpression(2),
        for: UnsignedIntegerConstantExpression(3)
      ),
      "SUBSTRING('YOCKOW' FROM 2 FOR 3)"
    )
    assertDescription(
      SubstringFunction(
        targetText: StringConstantExpression("YOCKOW"),
        similar: StringConstantExpression(###"%#"O_K#"_"###),
        escape: StringConstantExpression("#")
      ),
      ###"SUBSTRING('YOCKOW' SIMILAR '%#"O_K#"_' ESCAPE '#')"###
    )
  }

  @Test func test_TableReferenceExpression() {
    assertDescription(
      RelationTableReference(
        RelationExpression("myTable"),
        alias: AliasClause(alias: "myAlias")
      ),
      "myTable AS myAlias"
    )

    assertDescription(
      FunctionTableReference(
        lateral: true,
        function: TableFunction(functionCall: CurrentDate.currentDate),
        alias: FunctionAliasClause(AliasClause(alias: "myAlias"))
      ),
      "LATERAL CURRENT_DATE AS myAlias"
    )

    assertDescription(
      XMLTableReference(
        lateral: true,
        function: XMLTableExpression(
          namespaces: XMLNamespaceList([
            XMLNamespaceListElement(
              uri: StringConstantExpression("https://example.com/xml"),
              as: "myns"
            )
          ]),
          row: StringConstantExpression("//ROWS/ROW"),
          passing: XMLPassingArgument(xml: ColumnReference(columnName: "xmlData")),
          columns: .init([
            .init(
              name: "id",
              type: TypeName(NumericTypeName.int),
              options: [.path(StringConstantExpression("@id"))]
            ),
            .forOrdinality(withName: "ordinalityCol"),
          ])
        ),
        alias: AliasClause(alias: "xmlAlias")
      ),
      "LATERAL " +
      "XMLTABLE(XMLNAMESPACES('https://example.com/xml' AS myns), '//ROWS/ROW' PASSING xmlData" +
      " COLUMNS id INT PATH '@id', ordinalityCol FOR ORDINALITY)" +
      " AS xmlAlias"
    )

    assertDescription(
      SelectTableReference<ValuesClause>(
        lateral: true,
        parenthesizing: ValuesClause([
          [UnsignedIntegerConstantExpression(0), StringConstantExpression("zero")]
        ]),
        alias: AliasClause(alias: "myAlias")
      ),
      "LATERAL (VALUES (0, 'zero')) AS myAlias"
    )

    assertDescription(
      JoinedTableAliasReference(
        parenthesizing: CrossJoinedTable(
          RelationTableReference(RelationExpression("leftTable")),
          RelationTableReference(RelationExpression("rightTable"))
        ),
        alias: AliasClause(alias: "joinedAlias")
      ),
      "(leftTable CROSS JOIN rightTable) AS joinedAlias"
    )
  }

  @Test func test_TrimFunction() {
    assertDescription(
      TrimFunction(trimmingEnd: .both, trimCharacters: "hoge", from: "hogeYOCKOWhoge"),
      "TRIM(BOTH 'hoge' FROM 'hogeYOCKOWhoge')"
    )
  }

  @Test func test_TypeCastFunction() {
    assertDescription(
      TypeCastFunction(UnsignedIntegerConstantExpression(0), as: NumericTypeName.bigInt.typeName),
      "CAST(0 AS BIGINT)"
    )
  }

  @Test func test_XMLElementFunction() {
    assertDescription(
      XMLElementFunction(
        name: "foo",
        attributes: .init([XMLAttribute(name: "bar", value: "baz")]),
        contents: GeneralExpressionList([StringConstantExpression("content")])
      ),
      "XMLELEMENT(NAME foo, XMLATTRIBUTES('baz' AS bar), 'content')"
    )
  }

  @Test func test_XMLExistsFunction() {
    assertDescription(
      XMLExistsFunction(
        xmlQuery: "//town[text() = 'Toronto']",
        argument: .init(
          defaultMechanism: .byValue,
          xml: "<towns><town>Toronto</town><town>Ottawa</town></towns>"
        )
      ),
      "XMLEXISTS('//town[text() = ''Toronto'']' PASSING BY VALUE '<towns><town>Toronto</town><town>Ottawa</town></towns>')"
    )
  }

  @Test func test_XMLForestFunction() {
    assertDescription(
      XMLForestFunction(XMLAttributeList([
        XMLAttribute(name: "someString", value: "value"),
        XMLAttribute(name: "someInteger", value: UnsignedIntegerConstantExpression(123)),
      ])),
      "XMLFOREST('value' AS someString, 123 AS someInteger)"
    )
  }

  @Test func test_XMLParseFunction() {
    assertDescription(
      XMLParseFunction(
        .document,
        text: #"<?xml version="1.0"?><foo><bar>hoge</bar><baz>fuga</baz></foo>"#
      ),
      #"XMLPARSE(DOCUMENT '<?xml version="1.0"?><foo><bar>hoge</bar><baz>fuga</baz></foo>')"#
    )
  }

  @Test func test_XMLPIFunction() {
    assertDescription(
      XMLPIFunction(name: "php", content: #"echo "hello world";"#),
      #"XMLPI(NAME php, 'echo "hello world";')"#
    )
  }

  @Test func test_XMLRootFunction() {
    assertDescription(
      XMLRootFunction(
        xml: XMLParseFunction(.document, text: "<content>foo</content>"),
        version: "1.0",
        standalone: .yes
      ),
      "XMLROOT(XMLPARSE(DOCUMENT '<content>foo</content>'), VERSION '1.0', STANDALONE YES)"
    )
  }

  @Test func test_XMLSerializeFunction() throws {
    assertDescription(
      XMLSerializeFunction(
        .content,
        xml: XMLParseFunction(.content, text: "<content>foo</content>"),
        as: try #require(GenericTypeName(.text)),
        indentOption: .noIndent
      ),
      "XMLSERIALIZE(CONTENT XMLPARSE(CONTENT '<content>foo</content>') AS TEXT NO INDENT)"
    )
  }

  @Test func test_XMLTableExpression() {
    assertDescription(
      XMLTableExpression(
        namespaces: XMLNamespaceList([
          XMLNamespaceListElement(
            uri: StringConstantExpression("https://example.com/xml"),
            as: "myns"
          )
        ]),
        row: StringConstantExpression("//ROWS/ROW"),
        passing: XMLPassingArgument(xml: ColumnReference(columnName: "xmlData")),
        columns: .init([
          .init(
            name: "id",
            type: TypeName(NumericTypeName.int),
            options: [.path(StringConstantExpression("@id"))]
          ),
          .forOrdinality(withName: "ordinalityCol"),
        ])
      ),
      "XMLTABLE(XMLNAMESPACES('https://example.com/xml' AS myns), '//ROWS/ROW' PASSING xmlData" +
      " COLUMNS id INT PATH '@id', ordinalityCol FOR ORDINALITY)"
    )
  }

  @Test func test_common_a_expr_b_expr() throws {
  expr_TYPECAST_Typename:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(UnsignedIntegerConstantExpression(0), as: .int),
        "0::INT"
      )
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(StringConstantExpression("string"), as: .text),
        "'string'::TEXT"
      )
    }
  expr_plus_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(1).plus(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "1 + 2")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_minus_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).minus(
        UnsignedIntegerConstantExpression(1)
      )
      assertDescription(invocation, "2 - 1")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_multiply_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).multiply(
        UnaryPrefixMinusOperatorInvocation(UnsignedIntegerConstantExpression(2))
      )
      assertDescription(invocation, "2 * -2")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_divide_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(6).divide(
        UnsignedIntegerConstantExpression(3)
      )
      assertDescription(invocation, "6 / 3")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_modulo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(5).modulo(
        UnsignedIntegerConstantExpression(4)
      )
      assertDescription(invocation, "5 % 4")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_exponent_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).exponent(
        UnsignedIntegerConstantExpression(3)
      )
      assertDescription(invocation, "2 ^ 3")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_lessThan_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).lessThan(
        UnsignedIntegerConstantExpression(3)
      )
      assertDescription(invocation, "2 < 3")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_greaterThan_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(3).greaterThan(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "3 > 2")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_equalTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(7).equalTo(
        UnsignedIntegerConstantExpression(7)
      )
      assertDescription(invocation, "7 = 7")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_lessThanOrEqualTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(1).lessThanOrEqualTo(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "1 <= 2")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_greaterThanOrEqualTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).greaterThanOrEqualTo(
        UnsignedIntegerConstantExpression(1)
      )
      assertDescription(invocation, "2 >= 1")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_notEqualTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(1).notEqualTo(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "1 <> 2")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_qual_Op_expr:
    do {
      let invocation = BinaryInfixQualifiedGeneralOperatorInvocation(
        BooleanConstantExpression.true,
        QualifiedGeneralOperator(
          OperatorConstructor(
            LabeledOperator(labels: ["myOp"], try Token.Operator("|||||"))
          )
        ),
        BooleanConstantExpression.false
      )
      assertDescription(invocation, "TRUE OPERATOR(myOp.|||||) FALSE")
    }
  qual_Op_expr:
    do {
      let invocation = UnaryPrefixQualifiedGeneralOperatorInvocation(
        QualifiedGeneralOperator(
          OperatorConstructor(
            LabeledOperator(labels: ["myPrefixOp"], try Token.Operator("+@-"))
          )
        ),
        UnsignedFloatConstantExpression(1.23)
      )
      assertDescription(invocation, "OPERATOR(myPrefixOp.+@-) 1.23")
      #expect(invocation as Any is any GeneralExpression)
      #expect(invocation as Any is any RestrictedExpression)
    }
  expr_IS_DISTINCT_FROM_expr:
    do {
      let expr = UnsignedIntegerConstantExpression(7).isDistinctFrom(NullConstantExpression.null)
      assertDescription(expr, "7 IS DISTINCT FROM NULL")
      #expect(expr as Any is any GeneralExpression)
      #expect(expr as Any is any RestrictedExpression)
    }
  expr_IS_NOT_DISTINCT_FROM_expr:
    do {
      let expr = UnsignedIntegerConstantExpression(7).isNotDistinctFrom(NullConstantExpression.null)
      assertDescription(expr, "7 IS NOT DISTINCT FROM NULL")
      #expect(expr as Any is any GeneralExpression)
      #expect(expr as Any is any RestrictedExpression)
    }
  expr_IS_DOCUMENT:
    do {
      let expr = StringConstantExpression("xml").isDocumentExpression
      assertDescription(expr, "'xml' IS DOCUMENT")
      #expect(expr as Any is any GeneralExpression)
      #expect(expr as Any is any RestrictedExpression)
    }
  expr_IS_NOT_DOCUMENT:
    do {
      let expr = StringConstantExpression("xml").isNotDocumentExpression
      assertDescription(expr, "'xml' IS NOT DOCUMENT")
      #expect(expr as Any is any GeneralExpression)
      #expect(expr as Any is any RestrictedExpression)
    }
  }

  @Test func test_a_expr() throws {
  a_expr_COLLATE_any_name:
    do {
      assertDescription(
        StringConstantExpression("string").collate(.locale(Locale(identifier: "ja-JP"))),
        #"'string' COLLATE "ja_JP""#
      )
    }
  a_expr_AT_TIME_ZONE_a_expr:
    do {
      assertDescription(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: ConstantDateTimeTypeName.timestamp,
          string: "2024-06-06 18:18:18"
        ).atTimeZone(
          try #require(TimeZone(identifier: "Asia/Tokyo"))
        ),
        "TIMESTAMP '2024-06-06 18:18:18' AT TIME ZONE 'Asia/Tokyo'"
      )
      assertDescription(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: ConstantDateTimeTypeName.timestamp,
          string: "2024-06-06 18:18:18"
        ).atTimeZone(
          try #require(TimeZone(identifier: "Asia/Tokyo"))
        ).atTimeZone(
          try #require(TimeZone(identifier: "America/Chicago"))
        ),
        "TIMESTAMP '2024-06-06 18:18:18' AT TIME ZONE 'Asia/Tokyo' AT TIME ZONE 'America/Chicago'"
      )
    }
  a_expr_AND_a_expr:
    do {
      assertDescription(
        BooleanConstantExpression.true.and(BooleanConstantExpression.false),
        "TRUE AND FALSE"
      )
    }
  a_expr_OR_a_expr:
    do {
      assertDescription(
        BooleanConstantExpression.true.or(BooleanConstantExpression.false),
        "TRUE OR FALSE"
      )
    }
  NOT_a_expr:
    do {
      assertDescription(
        UnaryPrefixNotOperatorInvocation(BooleanConstantExpression.true),
        "NOT TRUE"
      )
    }
  a_expr_LIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").like(StringConstantExpression("_b_")),
        "'abc' LIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").like(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' LIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_NOT_LIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").notLike(StringConstantExpression("_b_")),
        "'abc' NOT LIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").notLike(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' NOT LIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_ILIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").caseInsensitiveLike(StringConstantExpression("_b_")),
        "'abc' ILIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").caseInsensitiveLike(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' ILIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_NOT_ILIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").notCaseInsensitiveLike(StringConstantExpression("_b_")),
        "'abc' NOT ILIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").notCaseInsensitiveLike(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' NOT ILIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_SIMILAR_TO_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").similarTo(StringConstantExpression("_b_")),
        "'abc' SIMILAR TO '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").similarTo(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' SIMILAR TO '_b_' ESCAPE 'e'"
      )
    }
  a_expr_NOT_SIMILAR_TO_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").notSimilarTo(StringConstantExpression("_b_")),
        "'abc' NOT SIMILAR TO '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").notSimilarTo(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' NOT SIMILAR TO '_b_' ESCAPE 'e'"
      )
    }
  a_expr_IS_NULL:
    do {
      assertDescription(
        UnsignedFloatConstantExpression(1.2).isNullExpression,
        "1.2 IS NULL"
      )
    }
  a_expr_IS_NOT_NULL:
    do {
      assertDescription(
        StringConstantExpression("null").isNotNullExpression,
        "'null' IS NOT NULL"
      )
    }
  row_OVERLAPS_row:
    do {
      assertDescription(
        BinaryInfixOverlapsOperatorInvocation(
          RowExpression(fields: [
            try #require(GenericTypeCastStringLiteralSyntax(typeName: .date, string: "2024-03-21")),
            try #require(GenericTypeCastStringLiteralSyntax(typeName: .interval, string: "100 days")),
          ]),
          RowExpression(fields: [
            try #require(GenericTypeCastStringLiteralSyntax(typeName: .date, string: "2024-06-01")),
            try #require(GenericTypeCastStringLiteralSyntax(typeName: .date, string: "2024-06-30")),
          ])
        ),
        "(DATE '2024-03-21', INTERVAL '100 days') OVERLAPS (DATE '2024-06-01', DATE '2024-06-30')"
      )
    }

  a_expr_IS_TRUE:
    do {
      assertDescription(
        BooleanConstantExpression.true.isTrueExpression,
        "TRUE IS TRUE"
      )
    }
  a_expr_IS_NOT_TRUE:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(
          NullConstantExpression.null,
          as: .boolean
        ).isNotTrueExpression,
        "NULL::BOOLEAN IS NOT TRUE"
      )
    }
  a_expr_IS_FALSE:
    do {
      assertDescription(
        BooleanConstantExpression.false.isFalseExpression,
        "FALSE IS FALSE"
      )
    }
  a_expr_IS_NOT_FALSE:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(
          NullConstantExpression.null,
          as: .boolean
        ).isNotFalseExpression,
        "NULL::BOOLEAN IS NOT FALSE"
      )
    }
  a_expr_IS_UNKNOWN:
    do {
      assertDescription(
        BooleanConstantExpression.false.isUnknownExpression,
        "FALSE IS UNKNOWN"
      )
    }
  a_expr_IS_NOT_UNKNOWN:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(
          NullConstantExpression.null,
          as: .boolean
        ).isNotUnknownExpression,
        "NULL::BOOLEAN IS NOT UNKNOWN"
      )
    }
  a_expr_BETWEEN_b_expr_AND_a_expr:
    do {
      assertDescription(
        UnsignedIntegerConstantExpression(2).between(
          UnsignedIntegerConstantExpression(1),
          and: UnsignedIntegerConstantExpression(3)
        ),
        "2 BETWEEN 1 AND 3"
      )
    }
  a_expr_NOT_BETWEEN_b_expr_AND_a_expr:
    do {
      assertDescription(
        UnsignedIntegerConstantExpression(2).notBetween(
          UnsignedIntegerConstantExpression(1),
          and: UnsignedIntegerConstantExpression(3)
        ),
        "2 NOT BETWEEN 1 AND 3"
      )
    }
  a_expr_IN_in_expr:
    do {
      assertDescription(
        ColumnReference(identifier: ColumnIdentifier("myColumn")).in(GeneralExpressionList([
          StringConstantExpression("a"),
          StringConstantExpression("b"),
          StringConstantExpression("c"),
        ])),
        "myColumn IN ('a', 'b', 'c')"
      )
    }
  a_expr_NOT_IN_in_expr:
    do {
      assertDescription(
        UnsignedIntegerConstantExpression(1).notIn(
          ValuesClause([
            [UnsignedIntegerConstantExpression(2)],
            [UnsignedIntegerConstantExpression(3)],
            [UnsignedIntegerConstantExpression(4)],
          ])
        ),
        "1 NOT IN (VALUES (2), (3), (4))"
      )
    }
  a_expr_subquery_Op_sub_type_expr:
    do {
      assertDescription(
        SatisfyExpression(
          value: ColumnReference(columnName: "myColumn"),
          comparator: .equalTo,
          kind: .any,
          subquery: SimpleSelectQuery(
            targets: [.all],
            from: FromClause([RelationTableReference("mySingleColumnTable")])
          )
        ),
        "myColumn = ANY (SELECT * FROM mySingleColumnTable)"
      )
      assertDescription(
        SatisfyExpression(
          value: ColumnReference(columnName: "myColumn"),
          comparator: .greaterThan,
          kind: .all,
          subquery: ValuesClause([
            [UnsignedIntegerConstantExpression(0)],
            [UnsignedIntegerConstantExpression(1)],
            [UnsignedIntegerConstantExpression(2)],
          ]).parenthesized
        ),
        "myColumn > ALL (VALUES (0), (1), (2))"
      )
      assertDescription(
        SatisfyExpression(
          value: ColumnReference(columnName: "myColumn"),
          comparator: .lessThan,
          kind: .some,
          array: ArrayConstructorExpression([
            UnsignedIntegerConstantExpression(0),
            UnsignedIntegerConstantExpression(1),
            UnsignedIntegerConstantExpression(2),
          ])
        ),
        "myColumn < SOME (ARRAY[0, 1, 2])"
      )
    }
  UNIQUE_opt_unique_null_treatment_select_with_parens:
    do {
      assertDescription(
        UniquePredicateExpression(
          nullTreatment: .notDistinct,
          subquery: ValuesClause([
            [UnsignedIntegerConstantExpression(0)]
          ]).parenthesized
        ),
        "UNIQUE NULLS NOT DISTINCT (VALUES (0))"
      )
    }
  a_expr_IS_NORMALIZED:
    do {
      assertDescription(
        IsNormalizedExpression(
          text: StringConstantExpression("hoge"),
          form: .nfd
        ),
        "'hoge' IS NFD NORMALIZED"
      )
    }
  a_expr_IS_NOT_NORMALIZED:
    do {
      assertDescription(
        IsNotNormalizedExpression(
          text: StringConstantExpression("hoge"),
          form: .nfd
        ),
        "'hoge' IS NOT NFD NORMALIZED"
      )
    }
  a_expr_IS_json_predicate_type_constraint:
    do {
      assertDescription(
        IsJSONTypeExpression(
          value: StringConstantExpression("json"),
          type: .jsonValue
        ),
        "'json' IS JSON VALUE"
      )
    }
  a_expr_IS_NOT_json_predicate_type_constraint:
    do {
      assertDescription(
        IsNotJSONTypeExpression(
          value: StringConstantExpression("json"),
          type: .jsonObject,
          keyUniquenessOption: .withUniqueKeys
        ),
        "'json' IS NOT JSON OBJECT WITH UNIQUE KEYS"
      )
    }
  DEFAULT:
    do {
      assertDescription(DefaultExpression.default, "DEFAULT")
    }
  }

  @Test func test_b_expr() {
    // Nothing to test because all tests of `b_expr` are executed in `test_common_a_expr_b_expr`.
  }

  @Test func test_c_expr() throws {
  columnref:
      do {
      #expect(ColumnReference(columnName: "my_column").description == "my_column")
      assertDescription(
        ColumnReference(
          tableName: TableName(schema: "public", name: "my_table"),
          columnName: "my_column"
        ),
        "public.my_table.my_column"
      )
    }
  AexprConst:
    do {
      #expect(UnsignedIntegerConstantExpression(12345).description == "12345")
      #expect(UnsignedFloatConstantExpression(1.2345).description == "1.2345")
      #expect(StringConstantExpression("string").description == "'string'")
      assertDescription(
        try #require(BitStringConstantExpression(.bitString("010", style: .binary))),
        "B'010'"
      )
      assertDescription(
        try #require(BitStringConstantExpression(.bitString("1FF", style: .hexadecimal))),
        "X'1FF'"
      )
      assertDescription(
        try #require(GenericTypeCastStringLiteralSyntax(typeName: "MY_TYPE", string: "value")),
        "MY_TYPE 'value'"
      )
      assertDescription(
        try #require(GenericTypeCastStringLiteralSyntax(
          typeName: "MY_TYPE",
          modifiers: .init([UnsignedIntegerConstantExpression(0).asFunctionArgument]),
          string: "value"
        )),
        "MY_TYPE (0) 'value'"
      )
      assertDescription(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: .timestamp(precision: 3, withTimeZone: true),
          string: "2004-10-19 10:23:54+02"
        ),
        "TIMESTAMP(3) WITH TIME ZONE '2004-10-19 10:23:54+02'"
      )
      assertDescription(
        try #require(ConstantIntervalTypeCastStringLiteralSyntax(
          string: "3 4:05:06",
          fields: .dayToSecond(precision: 3)
        )),
        "INTERVAL '3 4:05:06' DAY TO SECOND(3)"
      )
      assertDescription(
        try #require(ConstantIntervalTypeCastStringLiteralSyntax(
          string: "3 4:05:06",
          precision: 6
        )),
        "INTERVAL(6) '3 4:05:06'"
      )
      #expect(BooleanConstantExpression.true.description == "TRUE")
      #expect(BooleanConstantExpression.false.description == "FALSE")
      #expect(NullConstantExpression.null.description == "NULL")
    }
  PARAM_opt_indirection:
    do {
      #expect(PositionalParameterExpression(1).description == "$1")
      #expect(PositionalParameterExpression(2, indirection: [.any]).description == "$2.*")
    }
  lparen_aexpr_rparen_opt_indirection:
    do {
      assertDescription(
        ParenthesizedGeneralExpressionWithIndirection(
          UnsignedIntegerConstantExpression(1 as UInt),
          indirection: [.attributeName(.columnLabel("foo"))]
        ),
        "(1).foo"
      )
    }
  case_expr:
    do {
      assertDescription(
        CaseExpression(
          argument: ColumnReference(columnName: "a"),
          (when: UnsignedIntegerConstantExpression(1), then: StringConstantExpression("one")),
          (when: UnsignedIntegerConstantExpression(2), then: StringConstantExpression("two")),
          else: StringConstantExpression("other")
        ),
        "CASE a WHEN 1 THEN 'one' WHEN 2 THEN 'two' ELSE 'other' END"
      )
    }
  func_expr:
    do {
      // Tests are executed in other places such as `test_AggregateWindowFunction`.
    }
  select_with_parens_indirection:
    do {
      assertDescription(
        SelectExpression(
          parenthesizing: TableCommandSyntax("myTable"),
          indirection: Indirection([.any])
        ),
        "(TABLE myTable).*"
      )
    }
  EXISTS_select_with_parens:
    do {
      assertDescription(
        ExistsExpression(parenthesizing: SimpleSelectQuery(
          targets: TargetList([
            TargetElement(UnsignedIntegerConstantExpression(1)),
          ]),
          from: FromClause([
            RelationTableReference("myTable")
          ]),
          where: WhereClause(condition: BooleanConstantExpression.true)
        )),
        "EXISTS (SELECT 1 FROM myTable WHERE TRUE)"
      )
    }
  ARRAY_select_with_parens:
    do {
      assertDescription(
        ArrayConstructorExpression(
          parenthesizing: ValuesClause([
            [UnsignedIntegerConstantExpression(0)],
            [UnsignedIntegerConstantExpression(1)],
            [UnsignedIntegerConstantExpression(2)],
          ])
        ),
        "ARRAY(VALUES (0), (1), (2))"
      )
    }
  ARRAY_array_expr:
    do {
      assertDescription(
        ArrayConstructorExpression(.empty),
        "ARRAY[]"
      )
      assertDescription(
        ArrayConstructorExpression([
          UnsignedIntegerConstantExpression(1),
          UnsignedIntegerConstantExpression(2),
        ]),
        "ARRAY[1, 2]"
      )
      assertDescription(
        ArrayConstructorExpression([
          ArrayConstructorExpression.Subscript(UnsignedIntegerConstantExpression(1)),
          ArrayConstructorExpression.Subscript(UnsignedIntegerConstantExpression(2)),
        ]),
        "ARRAY[[1], [2]]"
      )
    }
  explicit_row:
    do {
      assertDescription(RowConstructorExpression.empty, "ROW()")
      assertDescription(
        RowConstructorExpression(fields: [UnsignedIntegerConstantExpression(0)]),
        "ROW(0)"
      )
    }
  implicit_row:
    do {
      assertDescription(
        ImplicitRowConstructorExpression(
          UnsignedIntegerConstantExpression(0),
          UnsignedFloatConstantExpression(1.2),
          StringConstantExpression("string")
        ),
        "(0, 1.2, 'string')"
      )
    }
  GROUPING_expr_list:
    do {
      assertDescription(
        GroupingExpression([
          ColumnReference(columnName: "col1"),
          ColumnReference(columnName: "col2"),
        ]),
        "GROUPING(col1, col2)"
      )
    }
  }
}

@Suite final class SQLGrammarStatementTests {
  @Test func test_CombinedSelectQuery() {
    assertDescription(
      SelectClause(ValuesClause([
        [UnsignedIntegerConstantExpression(0)],
        [UnsignedIntegerConstantExpression(1)],
        [UnsignedIntegerConstantExpression(2)],
      ])).union(
        .all,
        SelectClause(ValuesClause([
          [UnsignedIntegerConstantExpression(3)],
          [UnsignedIntegerConstantExpression(4)],
          [UnsignedIntegerConstantExpression(5)],
        ]))
      ),
      "VALUES (0), (1), (2) UNION ALL VALUES (3), (4), (5)"
    )
  }

  @Test func test_CreatePartitionTableStatement() {
    assertDescription(
      CreatePartitionTableStatement(
        name: "subTable",
        partitionOf: "parentTable",
        partitionBoundSpecification: .forValuesFrom(
          .init(item: .init(UnsignedIntegerConstantExpression(10))),
          to: [.maxValue]
        )
      ),
      "CREATE TABLE subTable PARTITION OF parentTable FOR VALUES FROM (10) TO (MAXVALUE)"
    )
    assertDescription(
      CreatePartitionTableStatement(
        temporariness: .localTemporary,
        name: "part1",
        partitionOf: "parentTable",
        partitionBoundSpecification: .forValuesWith(modulus: 4, remainder: 0)
      ),
      "CREATE LOCAL TEMPORARY TABLE part1 PARTITION OF parentTable " +
      "FOR VALUES WITH (MODULUS 4, REMAINDER 0)"
    )
  }

  @Test func test_CreateTableStatement() {
    assertDescription(
      CreateTableStatement(
        temporariness: .temporary,
        ifNotExists: true,
        name: "newTable",
        definitions: .init([
          ColumnDefinition(name: "col1", dataType: .int),
          ColumnDefinition(name: "col2", dataType: .boolean),
        ]),
        inherits: InheritClause(["parentTable"]),
        partitionSpecification: PartitionSpecification(
          strategy: .range,
          parameters: [PartitionSpecificationParameter(columnName: "col1")]
        ),
        accessMethod: TableAccessMethodClause(methodName: "myMethod"),
        storageParameters: .withoutOIDs,
        onCommit: .drop,
        tableSpace: .init("myTableSpace")
      ),
      "CREATE TEMPORARY TABLE IF NOT EXISTS newTable (col1 INT, col2 BOOLEAN) " +
      "INHERITS (parentTable) " +
      "PARTITION BY RANGE (col1) " +
      "USING myMethod " +
      "WITHOUT OIDS " +
      "ON COMMIT DROP " +
      "TABLESPACE myTableSpace"
    )
  }

  @Test func test_CreateTypedTableStatement() {
    assertDescription(
      CreateTypedTableStatement(
        temporariness: .unlogged,
        ifNotExists: false,
        name: "myTypedTable",
        of: "myType",
        definitions: .init([
          TableConstraint(constraint: .primaryKey(columns: ["myCol"])),
        ])
      ),
      "CREATE UNLOGGED TABLE myTypedTable OF myType (PRIMARY KEY (myCol))"
    )
  }

  @Test func test_DropTableStatement() {
    func __assert(
      _ dropTable: DropTableStatement,
      _ expectedDescription: String,
      sourceLocation: SourceLocation = #_sourceLocation
    ) {
      #expect(dropTable.description == expectedDescription, sourceLocation: sourceLocation)
    }

    __assert(
      DropTableStatement(
        ifExists: false,
        name: "my_table",
        behavior: nil
      ),
      "DROP TABLE my_table"
    )
    __assert(
      DropTableStatement(
        ifExists: true,
        names: [TableName("my_table1"), TableName("my_table2")],
        behavior: .restrict
      ),
      "DROP TABLE IF EXISTS my_table1, my_table2 RESTRICT"
    )
    __assert(
      DropTableStatement(
        names: [
          TableName(schema: "my_schema", name: "my_private_table1"),
          TableName(schema: "my_schema", name: "my_private_table2"),
        ]
      ),
      "DROP TABLE my_schema.my_private_table1, my_schema.my_private_table2"
    )
  }

  @Test func test_FullyFunctionalSelectQuery() {
    assertDescription(
      WithClause(
        recursive: true,
        queries: [
          CommonTableExpression(
            name: "withName",
            columnNames: nil,
            subquery: ValuesClause([
              [UnsignedIntegerConstantExpression(0), StringConstantExpression("zero")],
              [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
            ])
          )
        ]
      ).select(
        SimpleSelectQuery(
          targets: TargetList([.all]),
          from: FromClause([
            RelationTableReference("myTable")
          ])
        ).asClause,
        orderBy: SortClause(SortBy<BooleanConstantExpression>(.true))
      ),
      "WITH RECURSIVE withName AS (VALUES (0, 'zero'), (1, 'one')) " +
      "SELECT * FROM myTable ORDER BY TRUE"
    )
  }

  @Test func test_LegacyTransactionStatement() {
    assertDescription(
      LegacyTransactionStatement.begin(.transaction, modes: [
        .isolationLevel(.readCommitted),
        .deferrable,
      ]),
      "BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED, DEFERRABLE"
    )
  }

  @Test func test_PLpgSQLAssignmentStatement() {
    assertDescription(
      PLpgSQLAssignmentStatement(
        variable: .init("myVariable"),
        operator: .colonEquals,
        expression: .init(
          allOrDistinct: .all,
          targets: [.init(ColumnReference(identifier: "col1"), as: "colAlias")],
          from: FromClause([RelationTableReference("myTable")]),
          where: WhereClause(condition: BooleanConstantExpression.true),
          group: GroupClause(columnReferences: [.empty]),
          having: HavingClause(predicate: BooleanConstantExpression.true),
          window: WindowClause([
            WindowDefinition(
              name: "winName",
              specification: WindowSpecification(
                name: nil,
                partitionBy: nil,
                orderBy: SortClause(SortBy(BooleanConstantExpression.true)),
                frame: nil
              )
            )
          ]),
          orderBy: SortClause(SortBy<ColumnReference>(ColumnReference(columnName: "col1"))),
          limit: SelectLimitClause.limit(count: SelectLimitValue(10), offset: SelectOffsetValue(2)),
          forLocking: .forReadOnly
        )
      ),
      "myVariable := ALL col1 AS colAlias FROM myTable WHERE TRUE " +
      "GROUP BY () HAVING TRUE WINDOW winName AS (ORDER BY TRUE) " +
      "ORDER BY col1 LIMIT 10 OFFSET 2 FOR READ ONLY"
    )
  }

  @Test func test_SimpleSelectQuery() {
    assertDescription(
      SimpleSelectQuery.selectAllRows(
        targets: TargetList([
          TargetElement(ColumnReference(columnName: "a"), as: "alias_a"),
        ])
      ),
      "SELECT ALL a AS alias_a"
    )

    // TODO: More gramatically-valid tests requried.
  }

  @Test func test_StatementList() {
    assertDescription(
      StatementList(
        LegacyTransactionStatement.begin,
        LegacyTransactionStatement.end
      ),
      """
      BEGIN;
      END
      """
    )
  }

  @Test func test_TableCommandSyntax() {
    assertDescription(
      TableCommandSyntax(tableName: "myTable"),
      "TABLE myTable"
    )
  }

  @Test func test_TransactionStatement() {
    func __assertDescription(
      _ statement: TransactionStatement, _ expectedDescription: String,
      _ message: @autoclosure () -> String = "",
      filePath: StaticString = #filePath, line: UInt = #line
    ) {
      assertDescription(statement, expectedDescription, message(), filePath: filePath, line: line)
    }

    __assertDescription(.abort, "ABORT")
    __assertDescription(.abort(.transaction, and: .noChain), "ABORT TRANSACTION AND NO CHAIN")
    __assertDescription(.startTransaction, "START TRANSACTION")
    __assertDescription(.startTransaction(modes: [.readOnly]), "START TRANSACTION READ ONLY")
    __assertDescription(.commit, "COMMIT")
    __assertDescription(.commit(.work, and: .chain), "COMMIT WORK AND CHAIN")
    __assertDescription(.rollback, "ROLLBACK")
    __assertDescription(.rollback(.transaction, and: .noChain), "ROLLBACK TRANSACTION AND NO CHAIN")
    __assertDescription(.savePoint("mySavePoint"), "SAVEPOINT mySavePoint")
    __assertDescription(.releaseSavePoint("mySavePoint"), "RELEASE SAVEPOINT mySavePoint")
    __assertDescription(.release("mySavePoint"), "RELEASE mySavePoint")
    __assertDescription(.rollback(toSavePoint: "mySavePoint"), "ROLLBACK TO SAVEPOINT mySavePoint")
    __assertDescription(.rollback(.work, to: "mySavePoint"), "ROLLBACK WORK TO mySavePoint")
    __assertDescription(.prepareTransaction("myTransaction"), "PREPARE TRANSACTION 'myTransaction'")
    __assertDescription(.commitPrepared("myTransaction"), "COMMIT PREPARED 'myTransaction'")
    __assertDescription(.rollbackPrepared("myTransaction"), "ROLLBACK PREPARED 'myTransaction'")
  }
}


@Suite final class SQLGrammarMacroExpansionTests {
  @Test func test_bool() {
    #expect(#bool(true).description == "TRUE")
    #expect(#bool(false).description == "FALSE")
    #expect(#TRUE.description == "TRUE")
    #expect(#FALSE.description == "FALSE")
  }

  @Test func test_const() {
    #expect(#const("My String").description == #"'My String'"#)
    #expect(#const(12345).description == #"12345"#)
    #expect(#const(18446744073709551615 as UInt64).description == "18446744073709551615")
    #expect(#const(Int(-2)).description == "-2")
    #expect(#const(123.45).description == #"123.45"#)
    #expect(#const(+12345).description == #"+12345"#)
    #expect(#const(+123.45).description == #"+123.45"#)
    #expect(#const(-12345).description == #"-12345"#)
    #expect(#const(-123.45).description == #"-123.45"#)
    #expect(#const(true).description == "TRUE")
    #expect(#const(false).description == "FALSE")
  }

  @Test func test_TypeCastStringLiteralSyntax() {
    #expect(#DATE("2024-08-27").description == "DATE '2024-08-27'")
    assertDescription(
      #INTERVAL("3 years 3 mons 700 days 133:17:36.789"),
      "INTERVAL '3 years 3 mons 700 days 133:17:36.789'"
    )
    #expect(#TIMESTAMP("2004-10-19 10:23:54").description == "TIMESTAMP '2004-10-19 10:23:54'")
    assertDescription(
      #TIMESTAMPTZ("2004-10-19 10:23:54+09"),
      "TIMESTAMP WITH TIME ZONE '2004-10-19 10:23:54+09'"
    )
    assertDescription(
      #TIMESTAMP_WITH_TIME_ZONE("2004-10-19 10:23:54+09"),
      "TIMESTAMP WITH TIME ZONE '2004-10-19 10:23:54+09'"
    )
  }

  @Test func test_param() {
    #expect(#param(1).description == "$1")
    #expect(#paramExpr(2).description == "$2")
  }
}
#else
final class SQLGrammarTests: XCTestCase {
  func test_keywords() {
    XCTAssertNotNil(Token.keyword(from: "CREATE"))
    XCTAssertNotNil(Token.keyword(from: "Drop"))
    XCTAssertNotNil(Token.keyword(from: "none"))
    XCTAssertNil(Token.keyword(from: "hogehoge"))
  }

  func test_JoinedSQLTokenSequence() {
    var tokens: [Token] = []
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

  func test_FunctionApplication() {
    assertDescription(FunctionApplication(FunctionName("f"), arguments: nil), "f()")
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        arguments: FunctionArgumentList([UnsignedIntegerConstantExpression(0).asFunctionArgument])
      ),
      "f(0)"
    )
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        variadicArgument: UnsignedIntegerConstantExpression(0).asFunctionArgument,
        orderBy: SortClause(SortBy(ColumnReference(columnName: "col1")))
      ),
      "f(VARIADIC 0 ORDER BY col1)"
    )
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        arguments: FunctionArgumentList([UnsignedIntegerConstantExpression(0).asFunctionArgument]),
        variadicArgument: UnsignedIntegerConstantExpression(1).asFunctionArgument
      ),
      "f(0, VARIADIC 1)"
    )
    assertDescription(
      FunctionApplication(
        FunctionName("f"),
        aggregate: .distinct,
        arguments: FunctionArgumentList([
          UnsignedIntegerConstantExpression(0).asFunctionArgument,
          UnsignedIntegerConstantExpression(1).asFunctionArgument
        ])
      ),
      "f(DISTINCT 0, 1)"
    )
    assertDescription(FunctionApplication(FunctionName("f"), arguments: .any), "f(*)")
  }

  func test_FunctionName() {
    XCTAssertEqual(FunctionName("my_func").description, "my_func")
    XCTAssertEqual(FunctionName(ColumnReference(tableName: "s", columnName: "f")).description, "s.f")
  }

  func test_FunctionType() throws {
    assertDescription(
      FunctionType(
        copyingType: try XCTUnwrap(CopyingTypeColumnReference(table: "users", column: "user_id"))
      ),
      "users.user_id%TYPE"
    )
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

  func test_TypeName() {
    assertDescription(
      TypeName(NumericTypeName.int, arrayModifier: .oneDimensionalArray(size: 3)),
      "INT ARRAY[3]"
    )
    assertDescription(
      TypeName(CharacterTypeName.char, arrayModifier: .multipleDimensionalArray([nil, 3])),
      "CHAR[][3]"
    )
  }

  func test_TableFunction() {
    assertDescription(
      TableFunction(functionCall: CurrentDate.currentDate, withOrdinality: true),
      "CURRENT_DATE WITH ORDINALITY"
    )
    assertDescription(
      TableFunction(
        rowsFrom: TableFunction.RowsFromSyntax([
          TableFunction.RowsFromSyntax.Item(
            functionCall: CurrentUser.currentUser,
            columnDefinitions: [
              TableFunctionElement(column: "col1", type: TypeName(GenericTypeName.text))
            ]
          )
        ])
      ),
      "ROWS FROM(CURRENT_USER AS (col1 TEXT))"
    )
  }

  func test_OnCommitOption() {
    assertDescription(OnCommitOption.drop, "ON COMMIT DROP")
    assertDescription(OnCommitOption.deleteRows, "ON COMMIT DELETE ROWS")
  }

  func test_TableSpaceSpecifier() {
    assertDescription(TableSpaceSpecifier("myTableSpace"), "TABLESPACE myTableSpace")
  }

  func test_TableConstraint() {
  ELEMENTS:
    do {
      assertDescription(
        TableConstraintElement.check(
          BinaryInfixNotEqualToOperatorInvocation(
            ColumnReference(columnName: "myColumn"),
            UnsignedIntegerConstantExpression(100)
          ),
          noInherit: true,
          deferrable: .deferrable,
          checkConstraint: .initiallyImmediate
        ),
        "CHECK (myColumn <> 100) NO INHERIT DEFERRABLE INITIALLY IMMEDIATE"
      )
      assertDescription(
        TableConstraintElement.unique(
          nulls: .notDistinct,
          columns: ["col1", "col2"],
          include: .init(columns: ["col3", "col4"]),
          with: .init(["someKey": 0]),
          tableSpace: .init("myTableSpace"),
          deferrable: .notDeferrable,
          checkConstraint: .initiallyDeferred
        ),
        "UNIQUE NULLS NOT DISTINCT (col1, col2) INCLUDE (col3, col4) " +
        "WITH (someKey = 0) USING INDEX TABLESPACE myTableSpace " +
        "NOT DEFERRABLE INITIALLY DEFERRED"
      )
      assertDescription(
        TableConstraintElement.primaryKey(
          columns: ["col1", "col2"],
          include: .init(columns: ["col3", "col4"]),
          with: .init(["someKey": 1.2])
        ),
        "PRIMARY KEY (col1, col2) INCLUDE (col3, col4) WITH (someKey = 1.2)"
      )
      assertDescription(
        TableConstraintElement.exclude(
          using: .init(methodName: "myMethod"),
          elements: [
            ExclusionConstraintElement(
              IndexElement(columnName: "foo"),
              with: LabeledOperator(Token.Operator.lessThan)
            ),
            ExclusionConstraintElement(
              IndexElement(columnName: "bar"),
              with: LabeledOperator(Token.Operator.greaterThan)
            ),
          ],
          where: .init(predicate: BinaryInfixGreaterThanOperatorInvocation(
            ColumnReference("hoge"),
            UnsignedIntegerConstantExpression(0)
          ))
        ),
        "EXCLUDE USING myMethod (foo WITH <, bar WITH >) WHERE (hoge > 0)"
      )
      assertDescription(
        TableConstraintElement.foreignKey(
          columns: ["col1", "col2"],
          referenceTable: "refTable",
          referenceColumns: ["refCol1", "refCol2"],
          match: .full,
          actions: .init(onDelete: .cascade, onUpdate: .noAction)
        ),
        "FOREIGN KEY (col1, col2) REFERENCES refTable (refCol1, refCol2) MATCH FULL " +
        "ON DELETE CASCADE ON UPDATE NO ACTION"
      )
    }
  CONSTRAINTS:
    do {
      assertDescription(
        TableConstraint(name: "myConstraint", constraint: .unique(columns: ["col1"])),
        "CONSTRAINT myConstraint UNIQUE (col1)"
      )
    }
  }

  func test_ColumnConstraintElement() {
    assertDescription(ColumnConstraintElement.notNull, "NOT NULL")
    assertDescription(ColumnConstraintElement.null,  "NULL")
    assertDescription(
      ColumnConstraintElement.unique(
        nulls: .distinct,
        with: .init(["someKey": 0]),
        tableSpace: .init("myTableSpace")
      ),
      "UNIQUE NULLS DISTINCT WITH (someKey = 0) USING INDEX TABLESPACE myTableSpace"
    )
    assertDescription(ColumnConstraintElement.unique,  "UNIQUE")
    assertDescription(
      ColumnConstraintElement.primaryKey(
        with: .init(["someKey": 0]),
        tableSpace: .init("myTableSpace")
      ),
      "PRIMARY KEY WITH (someKey = 0) USING INDEX TABLESPACE myTableSpace"
    )
    assertDescription(ColumnConstraintElement.primaryKey, "PRIMARY KEY")
    assertDescription(
      ColumnConstraintElement.check(
        BinaryInfixGreaterThanOperatorInvocation(
          ColumnReference(columnName: "myCol"),
          UnsignedIntegerConstantExpression(0)
        ),
        noInherit: true
      ),
      "CHECK (myCol > 0) NO INHERIT"
    )
    assertDescription(
      ColumnConstraintElement.default(UnsignedFloatConstantExpression(1.2)),
      "DEFAULT 1.2"
    )
    assertDescription(
      ColumnConstraintElement.generatedAsIdentity(.always, sequenceOptions: [.cycle, .ownedByNone]),
      "GENERATED ALWAYS AS IDENTITY (CYCLE OWNED BY NONE)"
    )
    assertDescription(
      ColumnConstraintElement.generatedStoredValue(
        from: BinaryInfixPlusOperatorInvocation(
          ColumnReference(columnName: "otherCol"),
          UnsignedIntegerConstantExpression(1)
        )
      ),
      "GENERATED ALWAYS AS (otherCol + 1) STORED"
    )
    assertDescription(
      ColumnConstraintElement.references(
        referenceTable: "refTable",
        referenceColumns: ["refCol1", "refCol2"],
        match: .full,
        actions: .init(onDelete: .setNull, onUpdate: .noAction)
      ),
      "REFERENCES refTable (refCol1, refCol2) MATCH FULL ON DELETE SET NULL ON UPDATE NO ACTION"
    )
  }

  func test_ColumnQualifier() {
    assertDescription(
      ColumnQualifier.constraint(name: "myConstraint", element: .primaryKey),
      "CONSTRAINT myConstraint PRIMARY KEY"
    )
    assertDescription(ColumnQualifier.attribute(.deferrable), "DEFERRABLE")
    assertDescription(ColumnQualifier.collation(.c), "COLLATE \"C\"")
  }

  func test_ColumnQualifierList() {
    assertDescription(
      ColumnQualifierList(
        collation: .locale(Locale(identifier: "ja-JP")),
        constraints: [
          .init(
            .primaryKey,
            deferrable: .notDeferrable,
            checkConstraint: .initiallyImmediate
          )
        ]
      ),
      #"COLLATE "ja_JP" PRIMARY KEY NOT DEFERRABLE INITIALLY IMMEDIATE"#
    )
  }

  func test_ColumnDefinition() {
    assertDescription(ColumnDefinition(name: "prodDate", dataType: .date), "prodDate DATE")
    assertDescription(
      ColumnDefinition(
        name: "title",
        dataType: .varchar(40),
        qualifiers: .constraints([.init(.notNull)])
      ),
      "title VARCHAR(40) NOT NULL"
    )
    assertDescription(
      ColumnDefinition(
        name: "code",
        dataType: .char(5),
        qualifiers: .constraints([
          .init(NamedColumnConstraint(name: "firstKey", element: .primaryKey))
        ])
      ),
      "code CHAR(5) CONSTRAINT firstKey PRIMARY KEY"
    )
  }

  func test_TypedTableColumnDefinition() {
    assertDescription(
      TypedTableColumnDefinition(
        name: "salary",
        withOptions: [.init(.default(UnsignedIntegerConstantExpression(1000)))]
      ),
      "salary WITH OPTIONS DEFAULT 1000"
    )
  }

  func test_TableElement() {
    assertDescription(
      TableElementList([
        ColumnDefinition(name: "myCol", dataType: .int),
        TableConstraint(
          constraint: .check(
            BinaryInfixGreaterThanOperatorInvocation(
              ColumnReference(stringLiteral: "myCol"),
              UnsignedIntegerConstantExpression(0)
            )
          )
        )
      ]),
      "myCol INT, CHECK (myCol > 0)"
    )
    assertDescription(
      OptionalTypedTableElementList([
        TypedTableColumnDefinition(name: "myCol"),
        TableConstraint(
          constraint: .check(
            BinaryInfixGreaterThanOperatorInvocation(
              ColumnReference(stringLiteral: "myCol"),
              UnsignedIntegerConstantExpression(0)
            )
          )
        )
      ]),
      "(myCol, CHECK (myCol > 0))"
    )
  }

  func test_RawParseMode() {
    assertDescription(
      RawParseMode.default([DropTableStatement(name: "myOldTable")]),
      "DROP TABLE myOldTable"
    )
    assertDescription(RawParseMode.typeName(.int), "MODE_TYPE_NAME INT")
    assertDescription(
      RawParseMode.plpgSQLExpression(.init(allOrDistinct: .all)),
      "MODE_PLPGSQL_EXPR ALL"
    )
    assertDescription(
      RawParseMode.plpgSQLAssignment1(
        .init(
          variable: .init(Token.PositionalParameter(1)),
          operator: .equalTo,
          expression: .init(targets: [.all])
        )
      ),
      "MODE_PLPGSQL_ASSIGN1 $1 = *"
    )
  }
}

final class SQLGrammarClauseTests: XCTestCase {
  func test_AliasClause() {
    XCTAssertEqual(
      AliasClause(alias: "foo").description,
      "AS foo"
    )
    XCTAssertEqual(
      AliasClause(alias: "foo", columnAliases: ["bar", "baz"]).description,
      "AS foo (bar, baz)"
    )
  }

  func test_CollateClause() {
    assertDescription(
      CollateClause(name: .c),
      #"COLLATE "C""#
    )
  }

  func test_ConstraintTableSpaceClause() {
    assertDescription(
      ConstraintTableSpaceClause("myTableSpace"),
      "USING INDEX TABLESPACE myTableSpace"
    )
  }

  func test_CycleClause() {
    assertDescription(
      CycleClause(
        ["id"],
        set: "is_cycle",
        to: UnsignedIntegerConstantExpression(1),
        default: UnsignedIntegerConstantExpression(0),
        using: "path"
      ),
      "CYCLE id SET is_cycle TO 1 DEFAULT 0 USING path"
    )
  }

  func test_DistinctClause() {
    assertDescription(DistinctClause(expressions: nil), "DISTINCT")
    assertDescription(
      DistinctClause(expressions: [
        ColumnReference(columnName: "col1"),
        ColumnReference(columnName: "col2"),
      ]),
      "DISTINCT ON (col1, col2)"
    )
  }

  func test_FunctionAliasClause() {
    assertDescription(
      FunctionAliasClause(
        alias: "myAlias",
        columnAliases: ["colAlias1"]
      ),
      "AS myAlias (colAlias1)"
    )
    assertDescription(
      FunctionAliasClause(
        alias: "myAlias",
        columnDefinitions: [
          TableFunctionElement(column: "myCol1", type: TypeName(GenericTypeName.text))
        ]
      ),
      "AS myAlias (myCol1 TEXT)"
    )
  }

  func test_GroupClause() {
    assertDescription(
      GroupClause(columnReferences: [
        .expression(ColumnReference(columnName: "a")),
        .cube(CubeClause([
          ColumnReference(columnName: "b"),
          ColumnReference(columnName: "c"),
        ])),
        .groupingSets(GroupingSetsClause([
          GroupingElement(
            ParenthesizedGeneralExpressionWithIndirection(ColumnReference(columnName: "d"))
          ),
          GroupingElement(
            ParenthesizedGeneralExpressionWithIndirection(ColumnReference(columnName: "e"))
          ),
        ]))
      ]),
      "GROUP BY a, CUBE(b, c), GROUPING SETS((d), (e))"
    )
  }

  func test_HavingClause() {
    assertDescription(HavingClause(predicate: BooleanConstantExpression.true), "HAVING TRUE")
  }

  func test_InheritClause() {
    assertDescription(InheritClause(["mother", "father"]), "INHERITS (mother, father)")
  }

  func test_IntoClause() {
    XCTAssertEqual(
      IntoClause(.init(table: "my_temp_table")).description,
      "INTO TEMPORARY TABLE my_temp_table"
    )
  }

  func test_LockingClause() {
    assertDescription(LockingClause.forReadOnly, "FOR READ ONLY")
    assertDescription(
      LockingClause(LockingMode(for: .update, of: ["tableName1"], waitOption: .noWait)),
      "FOR UPDATE OF tableName1 NOWAIT"
    )
    assertDescription(
      LockingClause(LockingMode(for: .keyShare, of: ["tableName1"], waitOption: .skip)),
      "FOR KEY SHARE OF tableName1 SKIP LOCKED"
    )
  }

  func test_PartitionSpecification() {
    assertDescription(
      PartitionSpecification(
        strategy: .range,
        parameters: [.init(columnName: "col1"), .init(columnName: "col2")]
      ),
      "PARTITION BY RANGE (col1, col2)"
    )
    assertDescription(
      PartitionSpecification(
        strategy: .hash,
        parameters: [.init(columnName: "col1"), .init(columnName: "col2")]
      ),
      "PARTITION BY HASH (col1, col2)"
    )
  }

  func test_SearchClause() {
    assertDescription(
      SearchClause(.breadthFirst, by: ["id"], set: "orderCol"),
      "SEARCH BREADTH FIRST BY id SET orderCol"
    )
  }

  func test_SelectClause() {
    assertDescription(
      SelectClause(ValuesClause([
        [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
      ])),
      "VALUES (1, 'one')"
    )
  }

  func test_SelectLimitClause() {
    assertDescription(
      SelectLimitClause.limit(count: SelectLimitValue(10), offset: SelectOffsetValue(2)),
      "LIMIT 10 OFFSET 2"
    )
    assertDescription(
      SelectLimitClause.offset(
        .init(UnsignedIntegerConstantExpression(2)),
        .rows,
        fetch: .next,
        .init(UnsignedIntegerConstantExpression(10)),
        .rows,
        option: .withTies
      ),
      "OFFSET 2 ROWS FETCH NEXT 10 ROWS WITH TIES"
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

  func test_TableAccessMethodClause() {
    assertDescription(TableAccessMethodClause(methodName: "myMethod"), "USING myMethod")
  }

  func test_TableSampleClause() {
    XCTAssertEqual(
      TableSampleClause(
        samplingMethod: FunctionName("sampling"),
        arguments: .init(BooleanConstantExpression.true)
      ).description,
      "TABLESAMPLE sampling(TRUE)"
    )
    XCTAssertEqual(
      TableSampleClause(
        samplingMethod: FunctionName("sampling"),
        arguments: .init(BooleanConstantExpression.false),
        repeatable: RepeatableClause<UnsignedIntegerConstantExpression>(seed: 1)
      ).description,
      "TABLESAMPLE sampling(FALSE) REPEATABLE(1)"
    )
  }

  func test_ValuesClause() {
    assertDescription(
      ValuesClause([
        [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
        [UnsignedIntegerConstantExpression(2), StringConstantExpression("two")],
        [UnsignedIntegerConstantExpression(3), StringConstantExpression("three")],
      ]),
      "VALUES (1, 'one'), (2, 'two'), (3, 'three')"
    )
  }

  func test_WhereClause() {
    assertDescription(WhereClause(condition: BooleanConstantExpression.true), "WHERE TRUE")
  }

  func test_WithClause() {
    assertDescription(
      WithClause(
        recursive: true,
        queries: [
          CommonTableExpression(
            name: "withName",
            columnNames: nil,
            subquery: ValuesClause([[UnsignedIntegerConstantExpression(0)]])
          )
        ]
      ),
      "WITH RECURSIVE withName AS (VALUES (0))"
    )
  }

  func test_WithStorageParametersClause() {
    assertDescription(
      WithStorageParametersClause([
        .fillfactor: 50,
        .parallelWorkers: 4,
      ]),
      "WITH (fillfactor = 50, parallel_workers = 4)"
    )
    assertDescription(WithStorageParametersClause.withoutOIDs, "WITHOUT OIDS")
  }

  func test_WindowClause() {
    assertDescription(
      WindowClause([
        WindowDefinition(
          name: "winName",
          specification: WindowSpecification(
            name: nil,
            partitionBy: nil,
            orderBy: SortClause(SortBy(BooleanConstantExpression.true)),
            frame: nil
          )
        )
      ]),
      "WINDOW winName AS (ORDER BY TRUE)"
    )
  }
}

final class SQLGrammarExpressionTests: XCTestCase {
  func test_AggregateWindowFunction() {
    assertDescription(
      AggregateWindowFunction(
        application: FunctionApplication(
          "myAggFunc",
          arguments: FunctionArgumentList([
            FunctionArgumentExpression(StringConstantExpression("arg"))
          ])
        ),
        withinGroup: WithinGroupClause(
          orderBy: SortClause(SortBy<ColumnReference>(ColumnReference(columnName: "col1")))
        )
      ),
      "myAggFunc('arg') WITHIN GROUP(ORDER BY col1)"
    )
    assertDescription(
      AggregateWindowFunction(
        application: FunctionApplication(
          "myFunc",
          arguments: FunctionArgumentList([
            FunctionArgumentExpression(StringConstantExpression("arg"))
          ]),
          orderBy: SortClause(SortBy<ColumnReference>(ColumnReference(columnName: "col1")))
        ),
        filter: FilterClause(where: BooleanConstantExpression.true),
        window: OverClause(windowSpecification: WindowSpecification(
          name: "myWindow",
          partitionBy: PartitionClause(.init([ColumnReference(columnName: "myPart")])),
          orderBy: nil,
          frame: FrameClause(
            mode: .range,
            extent: .init(start: .unboundedPreceding, end: .currentRow),
            exclusion: .excludeNoOthers
          )
        ))
      ),
      "myFunc('arg' ORDER BY col1) FILTER(WHERE TRUE) OVER (myWindow PARTITION BY myPart RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS)"
    )
  }

  func test_CoalesceFunction() {
    assertDescription(
      CoalesceFunction([
        ColumnReference(columnName: "foo"),
        ColumnReference(columnName: "bar"),
        StringConstantExpression("Hello"),
      ]),
      "COALESCE(foo, bar, 'Hello')"
    )
  }

  func test_CommonTableExpression() {
    assertDescription(
      CommonTableExpression(
        name: "withName",
        columnNames: ["col1", "col2"],
        materialized: .notMaterialized,
        subquery: ValuesClause([
          [UnsignedIntegerConstantExpression(0), StringConstantExpression("zero")],
          [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
        ]),
        search: SearchClause(.breadthFirst, by: ["col1"], set: "orderCol"),
        cycle: CycleClause(["col1"], set: "isCycle", using: "path")
      ),
      "withName(col1, col2) AS NOT MATERIALIZED (VALUES (0, 'zero'), (1, 'one')) " +
      "SEARCH BREADTH FIRST BY col1 SET orderCol " +
      "CYCLE col1 SET isCycle USING path"
    )

    assertDescription(
      CommonTableExpressionList([
        CommonTableExpression(
          name: "withName1",
          columnNames: nil,
          subquery: ValuesClause([[UnsignedIntegerConstantExpression(1)]])
        ),
        CommonTableExpression(
          name: "withName2",
          columnNames: nil,
          subquery: ValuesClause([[UnsignedIntegerConstantExpression(2)]])
        ),
      ]),
      "withName1 AS (VALUES (1)), withName2 AS (VALUES (2))"
    )
  }

  func test_CurrentTime() {
    assertDescription(CurrentTime(), "CURRENT_TIME")
    assertDescription(CurrentTime(precision: 6), "CURRENT_TIME(6)")
  }

  func test_ExtractFunction() throws {
    assertDescription(
      ExtractFunction(
        field: .day,
        from: try XCTUnwrap(ConstantTypeCastStringLiteralSyntax(
          constantTypeName: ConstantDateTimeTypeName.timestamp,
          string: "2024-05-13 16:29:55"
        ))
      ),
      "EXTRACT(DAY FROM TIMESTAMP '2024-05-13 16:29:55')"
    )
  }

  func test_JSONAggregateWindowFunction() {
    assertDescription(
      JSONAggregateWindowFunction(
        JSONArrayAggregateFunction(
          value: JSONValueExpression(value: StringConstantExpression("foo"))
        ),
        filter: FilterClause(where: BooleanConstantExpression.true),
        window: .init(windowName: "myWindow")
      ),
      "JSON_ARRAYAGG('foo') FILTER(WHERE TRUE) OVER myWindow"
    )
  }

  func test_JSONArrayAggregateFunction() {
    assertDescription(
      JSONArrayAggregateFunction(
        value: JSONValueExpression(value: UnsignedIntegerConstantExpression(1)),
        orderBy: JSONArrayAggregateSortClause(SortBy(ColumnReference(columnName: "col1"))),
        nullOption: .nullOnNull,
        outputType: JSONOutputTypeClause(typeName: TypeName(GenericTypeName.json))
      ),
      "JSON_ARRAYAGG(1 ORDER BY col1 NULL ON NULL RETURNING JSON)"
    )
  }

  func test_JSONArrayFunction() {
    assertDescription(
      JSONArrayFunction(
        values: JSONValueExpressionList(values: [
          JSONValueExpression(value: StringConstantExpression("string")),
          JSONValueExpression(value: UnsignedIntegerConstantExpression(1)),
        ]),
        nullOption: .absentOnNull,
        outputType: .init(typeName: TypeName(GenericTypeName.text))
      ),
      "JSON_ARRAY('string', 1 ABSENT ON NULL RETURNING TEXT)"
    )
  }

  func test_JSONObjectAggregateFunction() {
    assertDescription(
      JSONObjectAggregateFunction(
        keyValuePair: JSONKeyValuePair(
          key: StringConstantExpression("key"),
          value: JSONValueExpression(value: StringConstantExpression("value"))
        ),
        nullOption: .absentOnNull,
        keyUniquenessOption: .withoutUniqueKeys,
        outputType: JSONOutputTypeClause(typeName: TypeName(GenericTypeName.json))
      ),
      "JSON_OBJECTAGG('key' : 'value' ABSENT ON NULL WITHOUT UNIQUE KEYS RETURNING JSON)"
    )
  }

  func test_JSONObjectFunction() {
    assertDescription(
      JSONObjectFunction(
        keyValuePairs: [
          StringConstantExpression("key"): JSONValueExpression(value: StringConstantExpression("value")),
        ],
        nullOption: .nullOnNull,
        keyUniquenessOption: .withUniqueKeys,
        outputType: JSONOutputTypeClause(
          typeName: TypeName(GenericTypeName.text),
          format: JSONFormatClause(encoding: JSONEncodingClause.utf8)
        )
      ),
      "JSON_OBJECT('key' : 'value' NULL ON NULL WITH UNIQUE KEYS RETURNING TEXT FORMAT JSON ENCODING UTF8)"
    )
  }

  func test_NormalizeFunction() {
    assertDescription(
      NormalizeFunction(text: StringConstantExpression("text")),
      "NORMALIZE('text')"
    )
    assertDescription(
      NormalizeFunction(text: StringConstantExpression("text"), form: .nfc),
      "NORMALIZE('text', NFC)"
    )
  }

  func test_NullIfFunction() {
    assertDescription(
      NullIfFunction(ColumnReference(columnName: "someValue"), StringConstantExpression("foo")),
      "NULLIF(someValue, 'foo')"
    )
  }

  func test_OverlayFunction() {
    assertDescription(
      OverlayFunction(
        targetText: StringConstantExpression("Txxxxas"),
        replacementText: StringConstantExpression("hom"),
        startIndex: UnsignedIntegerConstantExpression(2),
        length: UnsignedIntegerConstantExpression(4)
      ),
      "OVERLAY('Txxxxas' PLACING 'hom' FROM 2 FOR 4)"
    )
  }

  func test_PositionFunction() {
    assertDescription(
      PositionFunction(StringConstantExpression("yo"), in: StringConstantExpression("yockow")),
      "POSITION('yo' IN 'yockow')"
    )
  }

  func test_RelationExpression() {
    XCTAssertEqual(
      RelationExpression(TableName(schema: "my_schema", name: "my_table")).description,
      "my_schema.my_table"
    )
    XCTAssertEqual(
      RelationExpression(
        TableName(schema: "my_schema", name: "my_table"),
        includeDescendantTables: true
      ).description,
      "my_schema.my_table *"
    )
    XCTAssertEqual(
      RelationExpression(
        TableName(schema: "my_schema", name: "my_table"),
        includeDescendantTables: false
      ).description,
      "ONLY my_schema.my_table"
    )
  }

  func test_RowExpression() {
    assertDescription(
      RowExpression(fields: [
        UnsignedIntegerConstantExpression(0),
        UnsignedFloatConstantExpression(1.2),
        StringConstantExpression("string"),
      ]),
      "(0, 1.2, 'string')"
    )
    assertDescription(
      RowExpression(fields: [
        UnsignedIntegerConstantExpression(0),
      ]),
      "ROW(0)"
    )
    assertDescription(RowExpression(), "ROW()")
  }

  func test_SubstringFunction() {
    assertDescription(
      SubstringFunction(
        targetText: StringConstantExpression("YOCKOW"),
        from: UnsignedIntegerConstantExpression(2),
        for: UnsignedIntegerConstantExpression(3)
      ),
      "SUBSTRING('YOCKOW' FROM 2 FOR 3)"
    )
    assertDescription(
      SubstringFunction(
        targetText: StringConstantExpression("YOCKOW"),
        similar: StringConstantExpression(###"%#"O_K#"_"###),
        escape: StringConstantExpression("#")
      ),
      ###"SUBSTRING('YOCKOW' SIMILAR '%#"O_K#"_' ESCAPE '#')"###
    )
  }

  func test_TableReferenceExpression() {
    assertDescription(
      RelationTableReference(
        RelationExpression("myTable"),
        alias: AliasClause(alias: "myAlias")
      ),
      "myTable AS myAlias"
    )

    assertDescription(
      FunctionTableReference(
        lateral: true,
        function: TableFunction(functionCall: CurrentDate.currentDate),
        alias: FunctionAliasClause(AliasClause(alias: "myAlias"))
      ),
      "LATERAL CURRENT_DATE AS myAlias"
    )

    assertDescription(
      XMLTableReference(
        lateral: true,
        function: XMLTableExpression(
          namespaces: XMLNamespaceList([
            XMLNamespaceListElement(
              uri: StringConstantExpression("https://example.com/xml"),
              as: "myns"
            )
          ]),
          row: StringConstantExpression("//ROWS/ROW"),
          passing: XMLPassingArgument(xml: ColumnReference(columnName: "xmlData")),
          columns: .init([
            .init(
              name: "id",
              type: TypeName(NumericTypeName.int),
              options: [.path(StringConstantExpression("@id"))]
            ),
            .forOrdinality(withName: "ordinalityCol"),
          ])
        ),
        alias: AliasClause(alias: "xmlAlias")
      ),
      "LATERAL " +
      "XMLTABLE(XMLNAMESPACES('https://example.com/xml' AS myns), '//ROWS/ROW' PASSING xmlData" +
      " COLUMNS id INT PATH '@id', ordinalityCol FOR ORDINALITY)" +
      " AS xmlAlias"
    )

    assertDescription(
      SelectTableReference<ValuesClause>(
        lateral: true,
        parenthesizing: ValuesClause([
          [UnsignedIntegerConstantExpression(0), StringConstantExpression("zero")]
        ]),
        alias: AliasClause(alias: "myAlias")
      ),
      "LATERAL (VALUES (0, 'zero')) AS myAlias"
    )

    assertDescription(
      JoinedTableAliasReference(
        parenthesizing: CrossJoinedTable(
          RelationTableReference(RelationExpression("leftTable")),
          RelationTableReference(RelationExpression("rightTable"))
        ),
        alias: AliasClause(alias: "joinedAlias")
      ),
      "(leftTable CROSS JOIN rightTable) AS joinedAlias"
    )
  }

  func test_TrimFunction() {
    assertDescription(
      TrimFunction(trimmingEnd: .both, trimCharacters: "hoge", from: "hogeYOCKOWhoge"),
      "TRIM(BOTH 'hoge' FROM 'hogeYOCKOWhoge')"
    )
  }

  func test_TypeCastFunction() {
    assertDescription(
      TypeCastFunction(UnsignedIntegerConstantExpression(0), as: NumericTypeName.bigInt.typeName),
      "CAST(0 AS BIGINT)"
    )
  }

  func test_XMLElementFunction() {
    assertDescription(
      XMLElementFunction(
        name: "foo",
        attributes: .init([XMLAttribute(name: "bar", value: "baz")]),
        contents: GeneralExpressionList([StringConstantExpression("content")])
      ),
      "XMLELEMENT(NAME foo, XMLATTRIBUTES('baz' AS bar), 'content')"
    )
  }

  func test_XMLExistsFunction() {
    assertDescription(
      XMLExistsFunction(
        xmlQuery: "//town[text() = 'Toronto']",
        argument: .init(
          defaultMechanism: .byValue,
          xml: "<towns><town>Toronto</town><town>Ottawa</town></towns>"
        )
      ),
      "XMLEXISTS('//town[text() = ''Toronto'']' PASSING BY VALUE '<towns><town>Toronto</town><town>Ottawa</town></towns>')"
    )
  }

  func test_XMLForestFunction() {
    assertDescription(
      XMLForestFunction(XMLAttributeList([
        XMLAttribute(name: "someString", value: "value"),
        XMLAttribute(name: "someInteger", value: UnsignedIntegerConstantExpression(123)),
      ])),
      "XMLFOREST('value' AS someString, 123 AS someInteger)"
    )
  }

  func test_XMLParseFunction() {
    assertDescription(
      XMLParseFunction(
        .document,
        text: #"<?xml version="1.0"?><foo><bar>hoge</bar><baz>fuga</baz></foo>"#
      ),
      #"XMLPARSE(DOCUMENT '<?xml version="1.0"?><foo><bar>hoge</bar><baz>fuga</baz></foo>')"#
    )
  }

  func test_XMLPIFunction() {
    assertDescription(
      XMLPIFunction(name: "php", content: #"echo "hello world";"#),
      #"XMLPI(NAME php, 'echo "hello world";')"#
    )
  }

  func test_XMLRootFunction() {
    assertDescription(
      XMLRootFunction(
        xml: XMLParseFunction(.document, text: "<content>foo</content>"),
        version: "1.0",
        standalone: .yes
      ),
      "XMLROOT(XMLPARSE(DOCUMENT '<content>foo</content>'), VERSION '1.0', STANDALONE YES)"
    )
  }

  func test_XMLSerializeFunction() throws {
    assertDescription(
      XMLSerializeFunction(
        .content,
        xml: XMLParseFunction(.content, text: "<content>foo</content>"),
        as: try XCTUnwrap(GenericTypeName(.text)),
        indentOption: .noIndent
      ),
      "XMLSERIALIZE(CONTENT XMLPARSE(CONTENT '<content>foo</content>') AS TEXT NO INDENT)"
    )
  }

  func test_XMLTableExpression() {
    assertDescription(
      XMLTableExpression(
        namespaces: XMLNamespaceList([
          XMLNamespaceListElement(
            uri: StringConstantExpression("https://example.com/xml"),
            as: "myns"
          )
        ]),
        row: StringConstantExpression("//ROWS/ROW"),
        passing: XMLPassingArgument(xml: ColumnReference(columnName: "xmlData")),
        columns: .init([
          .init(
            name: "id",
            type: TypeName(NumericTypeName.int),
            options: [.path(StringConstantExpression("@id"))]
          ),
          .forOrdinality(withName: "ordinalityCol"),
        ])
      ),
      "XMLTABLE(XMLNAMESPACES('https://example.com/xml' AS myns), '//ROWS/ROW' PASSING xmlData" +
      " COLUMNS id INT PATH '@id', ordinalityCol FOR ORDINALITY)"
    )
  }

  func test_common_a_expr_b_expr() throws {
  expr_TYPECAST_Typename:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(UnsignedIntegerConstantExpression(0), as: .int),
        "0::INT"
      )
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(StringConstantExpression("string"), as: .text),
        "'string'::TEXT"
      )
    }
  expr_plus_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(1).plus(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "1 + 2")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_minus_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).minus(
        UnsignedIntegerConstantExpression(1)
      )
      assertDescription(invocation, "2 - 1")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_multiply_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).multiply(
        UnaryPrefixMinusOperatorInvocation(UnsignedIntegerConstantExpression(2))
      )
      assertDescription(invocation, "2 * -2")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_divide_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(6).divide(
        UnsignedIntegerConstantExpression(3)
      )
      assertDescription(invocation, "6 / 3")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_modulo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(5).modulo(
        UnsignedIntegerConstantExpression(4)
      )
      assertDescription(invocation, "5 % 4")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_exponent_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).exponent(
        UnsignedIntegerConstantExpression(3)
      )
      assertDescription(invocation, "2 ^ 3")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_lessThan_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).lessThan(
        UnsignedIntegerConstantExpression(3)
      )
      assertDescription(invocation, "2 < 3")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_greaterThan_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(3).greaterThan(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "3 > 2")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_equalTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(7).equalTo(
        UnsignedIntegerConstantExpression(7)
      )
      assertDescription(invocation, "7 = 7")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_lessThanOrEqualTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(1).lessThanOrEqualTo(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "1 <= 2")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_greaterThanOrEqualTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(2).greaterThanOrEqualTo(
        UnsignedIntegerConstantExpression(1)
      )
      assertDescription(invocation, "2 >= 1")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_notEqualTo_expr:
    do {
      let invocation = UnsignedIntegerConstantExpression(1).notEqualTo(
        UnsignedIntegerConstantExpression(2)
      )
      assertDescription(invocation, "1 <> 2")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_qual_Op_expr:
    do {
      let invocation = BinaryInfixQualifiedGeneralOperatorInvocation(
        BooleanConstantExpression.true,
        QualifiedGeneralOperator(
          OperatorConstructor(
            LabeledOperator(labels: ["myOp"], try Token.Operator("|||||"))
          )
        ),
        BooleanConstantExpression.false
      )
      assertDescription(invocation, "TRUE OPERATOR(myOp.|||||) FALSE")
    }
  qual_Op_expr:
    do {
      let invocation = UnaryPrefixQualifiedGeneralOperatorInvocation(
        QualifiedGeneralOperator(
          OperatorConstructor(
            LabeledOperator(labels: ["myPrefixOp"], try Token.Operator("+@-"))
          )
        ),
        UnsignedFloatConstantExpression(1.23)
      )
      assertDescription(invocation, "OPERATOR(myPrefixOp.+@-) 1.23")
      XCTAssertTrue(invocation as Any is any GeneralExpression)
      XCTAssertTrue(invocation as Any is any RestrictedExpression)
    }
  expr_IS_DISTINCT_FROM_expr:
    do {
      let expr = UnsignedIntegerConstantExpression(7).isDistinctFrom(NullConstantExpression.null)
      assertDescription(expr, "7 IS DISTINCT FROM NULL")
      XCTAssertTrue(expr as Any is any GeneralExpression)
      XCTAssertTrue(expr as Any is any RestrictedExpression)
    }
  expr_IS_NOT_DISTINCT_FROM_expr:
    do {
      let expr = UnsignedIntegerConstantExpression(7).isNotDistinctFrom(NullConstantExpression.null)
      assertDescription(expr, "7 IS NOT DISTINCT FROM NULL")
      XCTAssertTrue(expr as Any is any GeneralExpression)
      XCTAssertTrue(expr as Any is any RestrictedExpression)
    }
  expr_IS_DOCUMENT:
    do {
      let expr = StringConstantExpression("xml").isDocumentExpression
      assertDescription(expr, "'xml' IS DOCUMENT")
      XCTAssertTrue(expr as Any is any GeneralExpression)
      XCTAssertTrue(expr as Any is any RestrictedExpression)
    }
  expr_IS_NOT_DOCUMENT:
    do {
      let expr = StringConstantExpression("xml").isNotDocumentExpression
      assertDescription(expr, "'xml' IS NOT DOCUMENT")
      XCTAssertTrue(expr as Any is any GeneralExpression)
      XCTAssertTrue(expr as Any is any RestrictedExpression)
    }
  }

  func test_a_expr() throws {
  a_expr_COLLATE_any_name:
    do {
      assertDescription(
        StringConstantExpression("string").collate(.locale(Locale(identifier: "ja-JP"))),
        #"'string' COLLATE "ja_JP""#
      )
    }
  a_expr_AT_TIME_ZONE_a_expr:
    do {
      assertDescription(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: ConstantDateTimeTypeName.timestamp,
          string: "2024-06-06 18:18:18"
        ).atTimeZone(
          try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        ),
        "TIMESTAMP '2024-06-06 18:18:18' AT TIME ZONE 'Asia/Tokyo'"
      )
      assertDescription(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: ConstantDateTimeTypeName.timestamp,
          string: "2024-06-06 18:18:18"
        ).atTimeZone(
          try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        ).atTimeZone(
          try XCTUnwrap(TimeZone(identifier: "America/Chicago"))
        ),
        "TIMESTAMP '2024-06-06 18:18:18' AT TIME ZONE 'Asia/Tokyo' AT TIME ZONE 'America/Chicago'"
      )
    }
  a_expr_AND_a_expr:
    do {
      assertDescription(
        BooleanConstantExpression.true.and(BooleanConstantExpression.false),
        "TRUE AND FALSE"
      )
    }
  a_expr_OR_a_expr:
    do {
      assertDescription(
        BooleanConstantExpression.true.or(BooleanConstantExpression.false),
        "TRUE OR FALSE"
      )
    }
  NOT_a_expr:
    do {
      assertDescription(
        UnaryPrefixNotOperatorInvocation(BooleanConstantExpression.true),
        "NOT TRUE"
      )
    }
  a_expr_LIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").like(StringConstantExpression("_b_")),
        "'abc' LIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").like(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' LIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_NOT_LIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").notLike(StringConstantExpression("_b_")),
        "'abc' NOT LIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").notLike(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' NOT LIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_ILIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").caseInsensitiveLike(StringConstantExpression("_b_")),
        "'abc' ILIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").caseInsensitiveLike(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' ILIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_NOT_ILIKE_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").notCaseInsensitiveLike(StringConstantExpression("_b_")),
        "'abc' NOT ILIKE '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").notCaseInsensitiveLike(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' NOT ILIKE '_b_' ESCAPE 'e'"
      )
    }
  a_expr_SIMILAR_TO_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").similarTo(StringConstantExpression("_b_")),
        "'abc' SIMILAR TO '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").similarTo(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' SIMILAR TO '_b_' ESCAPE 'e'"
      )
    }
  a_expr_NOT_SIMILAR_TO_a_expr:
    do {
      assertDescription(
        StringConstantExpression("abc").notSimilarTo(StringConstantExpression("_b_")),
        "'abc' NOT SIMILAR TO '_b_'"
      )
      assertDescription(
        StringConstantExpression("abc").notSimilarTo(
          StringConstantExpression("_b_"),
          escape: StringConstantExpression("e")
        ),
        "'abc' NOT SIMILAR TO '_b_' ESCAPE 'e'"
      )
    }
  a_expr_IS_NULL:
    do {
      assertDescription(
        UnsignedFloatConstantExpression(1.2).isNullExpression,
        "1.2 IS NULL"
      )
    }
  a_expr_IS_NOT_NULL:
    do {
      assertDescription(
        StringConstantExpression("null").isNotNullExpression,
        "'null' IS NOT NULL"
      )
    }
  row_OVERLAPS_row:
    do {
      assertDescription(
        BinaryInfixOverlapsOperatorInvocation(
          RowExpression(fields: [
            try XCTUnwrap(GenericTypeCastStringLiteralSyntax(typeName: .date, string: "2024-03-21")),
            try XCTUnwrap(GenericTypeCastStringLiteralSyntax(typeName: .interval, string: "100 days")),
          ]),
          RowExpression(fields: [
            try XCTUnwrap(GenericTypeCastStringLiteralSyntax(typeName: .date, string: "2024-06-01")),
            try XCTUnwrap(GenericTypeCastStringLiteralSyntax(typeName: .date, string: "2024-06-30")),
          ])
        ),
        "(DATE '2024-03-21', INTERVAL '100 days') OVERLAPS (DATE '2024-06-01', DATE '2024-06-30')"
      )
    }

  a_expr_IS_TRUE:
    do {
      assertDescription(
        BooleanConstantExpression.true.isTrueExpression,
        "TRUE IS TRUE"
      )
    }
  a_expr_IS_NOT_TRUE:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(
          NullConstantExpression.null,
          as: .boolean
        ).isNotTrueExpression,
        "NULL::BOOLEAN IS NOT TRUE"
      )
    }
  a_expr_IS_FALSE:
    do {
      assertDescription(
        BooleanConstantExpression.false.isFalseExpression,
        "FALSE IS FALSE"
      )
    }
  a_expr_IS_NOT_FALSE:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(
          NullConstantExpression.null,
          as: .boolean
        ).isNotFalseExpression,
        "NULL::BOOLEAN IS NOT FALSE"
      )
    }
  a_expr_IS_UNKNOWN:
    do {
      assertDescription(
        BooleanConstantExpression.false.isUnknownExpression,
        "FALSE IS UNKNOWN"
      )
    }
  a_expr_IS_NOT_UNKNOWN:
    do {
      assertDescription(
        BinaryInfixTypeCastOperatorInvocation(
          NullConstantExpression.null,
          as: .boolean
        ).isNotUnknownExpression,
        "NULL::BOOLEAN IS NOT UNKNOWN"
      )
    }
  a_expr_BETWEEN_b_expr_AND_a_expr:
    do {
      assertDescription(
        UnsignedIntegerConstantExpression(2).between(
          UnsignedIntegerConstantExpression(1),
          and: UnsignedIntegerConstantExpression(3)
        ),
        "2 BETWEEN 1 AND 3"
      )
    }
  a_expr_NOT_BETWEEN_b_expr_AND_a_expr:
    do {
      assertDescription(
        UnsignedIntegerConstantExpression(2).notBetween(
          UnsignedIntegerConstantExpression(1),
          and: UnsignedIntegerConstantExpression(3)
        ),
        "2 NOT BETWEEN 1 AND 3"
      )
    }
  a_expr_IN_in_expr:
    do {
      assertDescription(
        ColumnReference(identifier: ColumnIdentifier("myColumn")).in(GeneralExpressionList([
          StringConstantExpression("a"),
          StringConstantExpression("b"),
          StringConstantExpression("c"),
        ])),
        "myColumn IN ('a', 'b', 'c')"
      )
    }
  a_expr_NOT_IN_in_expr:
    do {
      assertDescription(
        UnsignedIntegerConstantExpression(1).notIn(
          ValuesClause([
            [UnsignedIntegerConstantExpression(2)],
            [UnsignedIntegerConstantExpression(3)],
            [UnsignedIntegerConstantExpression(4)],
          ])
        ),
        "1 NOT IN (VALUES (2), (3), (4))"
      )
    }
  a_expr_subquery_Op_sub_type_expr:
    do {
      assertDescription(
        SatisfyExpression(
          value: ColumnReference(columnName: "myColumn"),
          comparator: .equalTo,
          kind: .any,
          subquery: SimpleSelectQuery(
            targets: [.all],
            from: FromClause([RelationTableReference("mySingleColumnTable")])
          )
        ),
        "myColumn = ANY (SELECT * FROM mySingleColumnTable)"
      )
      assertDescription(
        SatisfyExpression(
          value: ColumnReference(columnName: "myColumn"),
          comparator: .greaterThan,
          kind: .all,
          subquery: ValuesClause([
            [UnsignedIntegerConstantExpression(0)],
            [UnsignedIntegerConstantExpression(1)],
            [UnsignedIntegerConstantExpression(2)],
          ]).parenthesized
        ),
        "myColumn > ALL (VALUES (0), (1), (2))"
      )
      assertDescription(
        SatisfyExpression(
          value: ColumnReference(columnName: "myColumn"),
          comparator: .lessThan,
          kind: .some,
          array: ArrayConstructorExpression([
            UnsignedIntegerConstantExpression(0),
            UnsignedIntegerConstantExpression(1),
            UnsignedIntegerConstantExpression(2),
          ])
        ),
        "myColumn < SOME (ARRAY[0, 1, 2])"
      )
    }
  UNIQUE_opt_unique_null_treatment_select_with_parens:
    do {
      assertDescription(
        UniquePredicateExpression(
          nullTreatment: .notDistinct,
          subquery: ValuesClause([
            [UnsignedIntegerConstantExpression(0)]
          ]).parenthesized
        ),
        "UNIQUE NULLS NOT DISTINCT (VALUES (0))"
      )
    }
  a_expr_IS_NORMALIZED:
    do {
      assertDescription(
        IsNormalizedExpression(
          text: StringConstantExpression("hoge"),
          form: .nfd
        ),
        "'hoge' IS NFD NORMALIZED"
      )
    }
  a_expr_IS_NOT_NORMALIZED:
    do {
      assertDescription(
        IsNotNormalizedExpression(
          text: StringConstantExpression("hoge"),
          form: .nfd
        ),
        "'hoge' IS NOT NFD NORMALIZED"
      )
    }
  a_expr_IS_json_predicate_type_constraint:
    do {
      assertDescription(
        IsJSONTypeExpression(
          value: StringConstantExpression("json"),
          type: .jsonValue
        ),
        "'json' IS JSON VALUE"
      )
    }
  a_expr_IS_NOT_json_predicate_type_constraint:
    do {
      assertDescription(
        IsNotJSONTypeExpression(
          value: StringConstantExpression("json"),
          type: .jsonObject,
          keyUniquenessOption: .withUniqueKeys
        ),
        "'json' IS NOT JSON OBJECT WITH UNIQUE KEYS"
      )
    }
  DEFAULT:
    do {
      assertDescription(DefaultExpression.default, "DEFAULT")
    }
  }

  func test_b_expr() {
    // Nothing to test because all tests of `b_expr` are executed in `test_common_a_expr_b_expr`.
  }

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
        GenericTypeCastStringLiteralSyntax(typeName: "MY_TYPE", string: "value")?.description,
        "MY_TYPE 'value'"
      )
      XCTAssertEqual(
        GenericTypeCastStringLiteralSyntax(
          typeName: "MY_TYPE",
          modifiers: .init([UnsignedIntegerConstantExpression(0).asFunctionArgument]),
          string: "value"
        )?.description,
        "MY_TYPE (0) 'value'"
      )
      XCTAssertEqual(
        ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
          constantTypeName: .timestamp(precision: 3, withTimeZone: true),
          string: "2004-10-19 10:23:54+02"
        ).description,
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
  func_expr:
    do {
      // Tests are executed in other places such as `test_AggregateWindowFunction`.
    }
  select_with_parens_indirection:
    do {
      assertDescription(
        SelectExpression(
          parenthesizing: TableCommandSyntax("myTable"),
          indirection: Indirection([.any])
        ),
        "(TABLE myTable).*"
      )
    }
  EXISTS_select_with_parens:
    do {
      assertDescription(
        ExistsExpression(parenthesizing: SimpleSelectQuery(
          targets: TargetList([
            TargetElement(UnsignedIntegerConstantExpression(1)),
          ]),
          from: FromClause([
            RelationTableReference("myTable")
          ]),
          where: WhereClause(condition: BooleanConstantExpression.true)
        )),
        "EXISTS (SELECT 1 FROM myTable WHERE TRUE)"
      )
    }
  ARRAY_select_with_parens:
    do {
      assertDescription(
        ArrayConstructorExpression(
          parenthesizing: ValuesClause([
            [UnsignedIntegerConstantExpression(0)],
            [UnsignedIntegerConstantExpression(1)],
            [UnsignedIntegerConstantExpression(2)],
          ])
        ),
        "ARRAY(VALUES (0), (1), (2))"
      )
    }
  ARRAY_array_expr:
    do {
      assertDescription(
        ArrayConstructorExpression(.empty),
        "ARRAY[]"
      )
      assertDescription(
        ArrayConstructorExpression([
          UnsignedIntegerConstantExpression(1),
          UnsignedIntegerConstantExpression(2),
        ]),
        "ARRAY[1, 2]"
      )
      assertDescription(
        ArrayConstructorExpression([
          ArrayConstructorExpression.Subscript(UnsignedIntegerConstantExpression(1)),
          ArrayConstructorExpression.Subscript(UnsignedIntegerConstantExpression(2)),
        ]),
        "ARRAY[[1], [2]]"
      )
    }
  explicit_row:
    do {
      assertDescription(RowConstructorExpression.empty, "ROW()")
      assertDescription(
        RowConstructorExpression(fields: [UnsignedIntegerConstantExpression(0)]),
        "ROW(0)"
      )
    }
  implicit_row:
    do {
      assertDescription(
        ImplicitRowConstructorExpression(
          UnsignedIntegerConstantExpression(0),
          UnsignedFloatConstantExpression(1.2),
          StringConstantExpression("string")
        ),
        "(0, 1.2, 'string')"
      )
    }
  GROUPING_expr_list:
    do {
      assertDescription(
        GroupingExpression([
          ColumnReference(columnName: "col1"),
          ColumnReference(columnName: "col2"),
        ]),
        "GROUPING(col1, col2)"
      )
    }
  }
}

final class SQLGrammarStatementTests: XCTestCase {
  func test_CombinedSelectQuery() {
    assertDescription(
      SelectClause(ValuesClause([
        [UnsignedIntegerConstantExpression(0)],
        [UnsignedIntegerConstantExpression(1)],
        [UnsignedIntegerConstantExpression(2)],
      ])).union(
        .all,
        SelectClause(ValuesClause([
          [UnsignedIntegerConstantExpression(3)],
          [UnsignedIntegerConstantExpression(4)],
          [UnsignedIntegerConstantExpression(5)],
        ]))
      ),
      "VALUES (0), (1), (2) UNION ALL VALUES (3), (4), (5)"
    )
  }

  func test_CreatePartitionTableStatement() {
    assertDescription(
      CreatePartitionTableStatement(
        name: "subTable",
        partitionOf: "parentTable",
        partitionBoundSpecification: .forValuesFrom(
          .init(item: .init(UnsignedIntegerConstantExpression(10))),
          to: [.maxValue]
        )
      ),
      "CREATE TABLE subTable PARTITION OF parentTable FOR VALUES FROM (10) TO (MAXVALUE)"
    )
    assertDescription(
      CreatePartitionTableStatement(
        temporariness: .localTemporary,
        name: "part1",
        partitionOf: "parentTable",
        partitionBoundSpecification: .forValuesWith(modulus: 4, remainder: 0)
      ),
      "CREATE LOCAL TEMPORARY TABLE part1 PARTITION OF parentTable " +
      "FOR VALUES WITH (MODULUS 4, REMAINDER 0)"
    )
  }

  func test_CreateTableStatement() {
    assertDescription(
      CreateTableStatement(
        temporariness: .temporary,
        ifNotExists: true,
        name: "newTable",
        definitions: .init([
          ColumnDefinition(name: "col1", dataType: .int),
          ColumnDefinition(name: "col2", dataType: .boolean),
        ]),
        inherits: InheritClause(["parentTable"]),
        partitionSpecification: PartitionSpecification(
          strategy: .range,
          parameters: [PartitionSpecificationParameter(columnName: "col1")]
        ),
        accessMethod: TableAccessMethodClause(methodName: "myMethod"),
        storageParameters: .withoutOIDs,
        onCommit: .drop,
        tableSpace: .init("myTableSpace")
      ),
      "CREATE TEMPORARY TABLE IF NOT EXISTS newTable (col1 INT, col2 BOOLEAN) " +
      "INHERITS (parentTable) " +
      "PARTITION BY RANGE (col1) " +
      "USING myMethod " +
      "WITHOUT OIDS " +
      "ON COMMIT DROP " +
      "TABLESPACE myTableSpace"
    )
  }

  func test_CreateTypedTableStatement() {
    assertDescription(
      CreateTypedTableStatement(
        temporariness: .unlogged,
        ifNotExists: false,
        name: "myTypedTable",
        of: "myType",
        definitions: .init([
          TableConstraint(constraint: .primaryKey(columns: ["myCol"])),
        ])
      ),
      "CREATE UNLOGGED TABLE myTypedTable OF myType (PRIMARY KEY (myCol))"
    )
  }

  func test_DropTableStatement() {
    func __assert(
      _ dropTable: DropTableStatement,
      _ expectedDescription: String,
      file: StaticString = #filePath, line: UInt = #line
    ) {
      XCTAssertEqual(dropTable.description, expectedDescription, file: file, line: line)
    }

    __assert(
      DropTableStatement(
        ifExists: false,
        name: "my_table",
        behavior: nil
      ),
      "DROP TABLE my_table"
    )
    __assert(
      DropTableStatement(
        ifExists: true,
        names: [TableName("my_table1"), TableName("my_table2")],
        behavior: .restrict
      ),
      "DROP TABLE IF EXISTS my_table1, my_table2 RESTRICT"
    )
    __assert(
      DropTableStatement(
        names: [
          TableName(schema: "my_schema", name: "my_private_table1"),
          TableName(schema: "my_schema", name: "my_private_table2"),
        ]
      ),
      "DROP TABLE my_schema.my_private_table1, my_schema.my_private_table2"
    )
  }

  func test_FullyFunctionalSelectQuery() {
    assertDescription(
      WithClause(
        recursive: true,
        queries: [
          CommonTableExpression(
            name: "withName",
            columnNames: nil,
            subquery: ValuesClause([
              [UnsignedIntegerConstantExpression(0), StringConstantExpression("zero")],
              [UnsignedIntegerConstantExpression(1), StringConstantExpression("one")],
            ])
          )
        ]
      ).select(
        SimpleSelectQuery(
          targets: TargetList([.all]),
          from: FromClause([
            RelationTableReference("myTable")
          ])
        ).asClause,
        orderBy: SortClause(SortBy<BooleanConstantExpression>(.true))
      ),
      "WITH RECURSIVE withName AS (VALUES (0, 'zero'), (1, 'one')) " +
      "SELECT * FROM myTable ORDER BY TRUE"
    )
  }

  func test_LegacyTransactionStatement() {
    assertDescription(
      LegacyTransactionStatement.begin(.transaction, modes: [
        .isolationLevel(.readCommitted),
        .deferrable,
      ]),
      "BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED, DEFERRABLE"
    )
  }

  func test_PLpgSQLAssignmentStatement() {
    assertDescription(
      PLpgSQLAssignmentStatement(
        variable: .init("myVariable"),
        operator: .colonEquals,
        expression: .init(
          allOrDistinct: .all,
          targets: [.init(ColumnReference(identifier: "col1"), as: "colAlias")],
          from: FromClause([RelationTableReference("myTable")]),
          where: WhereClause(condition: BooleanConstantExpression.true),
          group: GroupClause(columnReferences: [.empty]),
          having: HavingClause(predicate: BooleanConstantExpression.true),
          window: WindowClause([
            WindowDefinition(
              name: "winName",
              specification: WindowSpecification(
                name: nil,
                partitionBy: nil,
                orderBy: SortClause(SortBy(BooleanConstantExpression.true)),
                frame: nil
              )
            )
          ]),
          orderBy: SortClause(SortBy<ColumnReference>(ColumnReference(columnName: "col1"))),
          limit: SelectLimitClause.limit(count: SelectLimitValue(10), offset: SelectOffsetValue(2)),
          forLocking: .forReadOnly
        )
      ),
      "myVariable := ALL col1 AS colAlias FROM myTable WHERE TRUE " +
      "GROUP BY () HAVING TRUE WINDOW winName AS (ORDER BY TRUE) " +
      "ORDER BY col1 LIMIT 10 OFFSET 2 FOR READ ONLY"
    )
  }

  func test_SimpleSelectQuery() {
    assertDescription(
      SimpleSelectQuery.selectAllRows(
        targets: TargetList([
          TargetElement(ColumnReference(columnName: "a"), as: "alias_a"),
        ])
      ),
      "SELECT ALL a AS alias_a"
    )

    // TODO: More gramatically-valid tests requried.
  }

  func test_StatementList() {
    assertDescription(
      StatementList(
        LegacyTransactionStatement.begin,
        LegacyTransactionStatement.end
      ),
      """
      BEGIN;
      END
      """
    )
  }

  func test_TableCommandSyntax() {
    assertDescription(
      TableCommandSyntax(tableName: "myTable"),
      "TABLE myTable"
    )
  }

  func test_TransactionStatement() {
    func __assertDescription(
      _ statement: TransactionStatement, _ expectedDescription: String,
      _ message: @autoclosure () -> String = "",
      file: StaticString = #filePath, line: UInt = #line
    ) {
      assertDescription(statement, expectedDescription, message(), filePath: file, line: line)
    }

    __assertDescription(.abort, "ABORT")
    __assertDescription(.abort(.transaction, and: .noChain), "ABORT TRANSACTION AND NO CHAIN")
    __assertDescription(.startTransaction, "START TRANSACTION")
    __assertDescription(.startTransaction(modes: [.readOnly]), "START TRANSACTION READ ONLY")
    __assertDescription(.commit, "COMMIT")
    __assertDescription(.commit(.work, and: .chain), "COMMIT WORK AND CHAIN")
    __assertDescription(.rollback, "ROLLBACK")
    __assertDescription(.rollback(.transaction, and: .noChain), "ROLLBACK TRANSACTION AND NO CHAIN")
    __assertDescription(.savePoint("mySavePoint"), "SAVEPOINT mySavePoint")
    __assertDescription(.releaseSavePoint("mySavePoint"), "RELEASE SAVEPOINT mySavePoint")
    __assertDescription(.release("mySavePoint"), "RELEASE mySavePoint")
    __assertDescription(.rollback(toSavePoint: "mySavePoint"), "ROLLBACK TO SAVEPOINT mySavePoint")
    __assertDescription(.rollback(.work, to: "mySavePoint"), "ROLLBACK WORK TO mySavePoint")
    __assertDescription(.prepareTransaction("myTransaction"), "PREPARE TRANSACTION 'myTransaction'")
    __assertDescription(.commitPrepared("myTransaction"), "COMMIT PREPARED 'myTransaction'")
    __assertDescription(.rollbackPrepared("myTransaction"), "ROLLBACK PREPARED 'myTransaction'")
  }
}


final class SQLGrammarMacroExpansionTests: XCTestCase {
  func test_bool() {
    XCTAssertEqual(#bool(true).description, "TRUE")
    XCTAssertEqual(#bool(false).description, "FALSE")
    XCTAssertEqual(#TRUE.description, "TRUE")
    XCTAssertEqual(#FALSE.description, "FALSE")
  }

  func test_const() {
    XCTAssertEqual(#const("My String").description, #"'My String'"#)
    XCTAssertEqual(#const(12345).description, #"12345"#)
    XCTAssertEqual(#const(18446744073709551615 as UInt64).description, "18446744073709551615")
    XCTAssertEqual(#const(Int(-2)).description, "-2")
    XCTAssertEqual(#const(123.45).description, #"123.45"#)
    XCTAssertEqual(#const(+12345).description, #"+12345"#)
    XCTAssertEqual(#const(+123.45).description, #"+123.45"#)
    XCTAssertEqual(#const(-12345).description, #"-12345"#)
    XCTAssertEqual(#const(-123.45).description, #"-123.45"#)
    XCTAssertEqual(#const(true).description, "TRUE")
    XCTAssertEqual(#const(false).description, "FALSE")
  }

  func test_TypeCastStringLiteralSyntax() {
    XCTAssertEqual(#DATE("2024-08-27").description, "DATE '2024-08-27'")
    XCTAssertEqual(
      #INTERVAL("3 years 3 mons 700 days 133:17:36.789").description,
      "INTERVAL '3 years 3 mons 700 days 133:17:36.789'"
    )
    XCTAssertEqual(#TIMESTAMP("2004-10-19 10:23:54").description, "TIMESTAMP '2004-10-19 10:23:54'")
    XCTAssertEqual(
      #TIMESTAMPTZ("2004-10-19 10:23:54+09").description,
      "TIMESTAMP WITH TIME ZONE '2004-10-19 10:23:54+09'"
    )
    XCTAssertEqual(
      #TIMESTAMP_WITH_TIME_ZONE("2004-10-19 10:23:54+09").description,
      "TIMESTAMP WITH TIME ZONE '2004-10-19 10:23:54+09'"
    )
  }

  func test_param() {
    XCTAssertEqual(#param(1).description, "$1")
    XCTAssertEqual(#paramExpr(2).description, "$2")
  }
}
#endif
