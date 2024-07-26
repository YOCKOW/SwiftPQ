/* *************************************************************************************************
 CommonTableExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An expression that is used as a query of `WITH` clause.
/// It is described as `common_table_expr` in "gram.y" while described as `with_query` in
/// [official documentation](https://www.postgresql.org/docs/16/sql-select.html).
public struct CommonTableExpression: Expression {
  public enum MaterializeOption: Segment {
    case materialized
    case notMaterialized

    private static let _materializedTokens: Array<Token> = [.materialized]
    private static let _notMaterializedTokens: Array<Token> = [.not, .materialized]

    public var tokens: Array<Token> {
      switch self {
      case .materialized:
        return MaterializeOption._materializedTokens
      case .notMaterialized:
        return MaterializeOption._notMaterializedTokens
      }
    }
  }

  public let name: Name

  public let columnNames: OptionalNameList

  public let materialized: MaterializeOption?

  public let subquery: any PreparableStatement

  public let searchClause: SearchClause?

  public let cycleClause: CycleClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting([
      name,
      columnNames.tokensMap({
        JoinedSQLTokenSequence(SingleToken.joiner, UnknownSQLTokenSequence($0))
      }),
      SingleToken.as,
      materialized,
      LeftParenthesis.leftParenthesis,
      subquery,
      RightParenthesis.rightParenthesis,
      searchClause,
      cycleClause,
    ])
  }

  public init(
    name: Name,
    columnNames: OptionalNameList,
    materialized: MaterializeOption? = nil,
    subquery: any PreparableStatement,
    search searchClause: SearchClause? = nil,
    cycle cycleClause: CycleClause? = nil
  ) {
    self.name = name
    self.columnNames = columnNames
    self.materialized = materialized
    self.subquery = subquery
    self.searchClause = searchClause
    self.cycleClause = cycleClause
  }
}

/// A list of `CommonTableExpression`. Described as `cte_list` in "gram.y".
public struct CommonTableExpressionList: TokenSequenceGenerator,
                                         InitializableWithNonEmptyList,
                                         ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = CommonTableExpression
  public typealias NonEmptyListElement = CommonTableExpression

  public let expressions: NonEmptyList<CommonTableExpression>

  public var tokens: JoinedSQLTokenSequence {
    return expressions.joinedByCommas()
  }

  public init(_ list: NonEmptyList<CommonTableExpression>) {
    self.expressions = list
  }
}
