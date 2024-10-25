/* *************************************************************************************************
 TableReferenceExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// Impl ref: https://www.postgresql.org/docs/16/queries-table-expressions.html

/// A type that represents `table_ref` in "gram.y".
public protocol TableReferenceExpression: Expression {}

/// A type that represents `joined_table` in "gram.y".
public protocol JoinedTableExpression: TableReferenceExpression, ParenthesizableExpression {}

extension Parenthesized: JoinedTableExpression,
                         TableReferenceExpression where EnclosedTokens: JoinedTableExpression {}


// MARK: - JoinedTableExpression a.k.a. joined_table implementations

/// Representation of `join_type` (and `opt_outer`).
public enum JoinType: TokenSequenceGenerator {
  case fullOuter
  case full
  case leftOuter
  case left
  case rightOuter
  case right
  case innter

  private static let _fullOuterTokens: Array<Token> = [.full, .outer]
  private static let _fullTokens: Array<Token> = [.full]
  private static let _leftOuterTokens: Array<Token> = [.left, .outer]
  private static let _leftTokens: Array<Token> = [.left]
  private static let _rightOuterTokens: Array<Token> = [.right, .outer]
  private static let _rightTokens: Array<Token> = [.right]
  private static let _innterTokens: Array<Token> = [.inner]

  public var tokens: Array<Token> {
    switch self {
    case .fullOuter:
      return JoinType._fullOuterTokens
    case .full:
      return JoinType._fullTokens
    case .leftOuter:
      return JoinType._leftOuterTokens
    case .left:
      return JoinType._leftTokens
    case .rightOuter:
      return JoinType._rightOuterTokens
    case .right:
      return JoinType._rightTokens
    case .innter:
      return JoinType._innterTokens
    }
  }
}

/// A specifier of join condition.
/// This type comprises not only `join_qual` but also `NATURAL` keyword.
public enum JoinCondition: Sendable {
  case usingColumnNames(NameList, alias: ColumnIdentifier? = nil)
  case predicate(any GeneralExpression)
  case natural

  /// `opt_alias_clause_for_join_using`
  fileprivate final class _AliasClauseForJoinUsing: Clause {
    let column: ColumnIdentifier
    let tokens: Array<Token>
    init(_ column: ColumnIdentifier) {
      self.column = column
      self.tokens = [.as, column.token]
    }
  }
}

/// A joined table by `CROSS JOIN`.
public struct CrossJoinedTable: JoinedTableExpression {
  let leftTable: any TableReferenceExpression
  let rightTable: any TableReferenceExpression

  private final class _CrossJoin: TokenSequenceGenerator {
    let tokens: Array<Token> = [.cross, .join]
    private init() {}
    static let crossJoin: _CrossJoin = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([
      leftTable, 
      _CrossJoin.crossJoin,
      rightTable,
    ] as [any TokenSequenceGenerator])
  }

  public init(
    _ leftTable: any TableReferenceExpression,
    _ rightTable: any TableReferenceExpression
  ) {
    self.leftTable = leftTable
    self.rightTable = rightTable
  }
}

/// A joined table with condition.
public struct QualifiedJoinedTable: JoinedTableExpression {
  public let leftTable: any TableReferenceExpression

  public let rightTable: any TableReferenceExpression

  public let type: JoinType?

  public let condition: JoinCondition

  public var tokens: JoinedTokenSequence {
    var sequences: [any TokenSequenceGenerator] = [leftTable]
    if case .natural = condition {
      sequences.append(SingleToken.natural)
    }
    if let joinType = type {
      sequences.append(joinType)
    }
    sequences.append(SingleToken.join)
    sequences.append(rightTable)
    switch condition {
    case .usingColumnNames(let columns, let alias):
      sequences.append(JoinedTokenSequence.compacting(
        SingleToken.using,
        columns.parenthesized,
        alias.map({ JoinCondition._AliasClauseForJoinUsing($0) })
      ))
    case .predicate(let booleanExpr):
      sequences.append(
        JoinedTokenSequence([SingleToken.on, booleanExpr] as [any TokenSequenceGenerator])
      )
    case .natural:
      break
    }
    return JoinedTokenSequence(sequences)
  }

  public init(
    _ leftTable: any TableReferenceExpression,
    _ rightTable: any TableReferenceExpression,
    type: JoinType? = nil,
    condition: JoinCondition
  ) {
    self.leftTable = leftTable
    self.rightTable = rightTable
    self.type = type
    self.condition = condition
  }
}

// MARK: END OF JoinedTableExpression a.k.a. joined_table implementations -

// MARK: - Usual TableReferenceExpression types.

/// One of `TableRefernceExpression`s that starts with relation expression.
///
/// This type is described as `relation_expr opt_alias_clause` or
/// `relation_expr opt_alias_clause tablesample_clause` in "gram.y".
public struct RelationTableReference: TableReferenceExpression {
  public let relation: RelationExpression

  public let alias: AliasClause?

  public let tableSample: TableSampleClause?

  public var tokens: JoinedTokenSequence {
    return .compacting(relation, alias, tableSample)
  }

  public init(
    _ relation: RelationExpression,
    alias: AliasClause? = nil,
    tableSample: TableSampleClause? = nil
  ) {
    self.relation = relation
    self.alias = alias
    self.tableSample = tableSample
  }
}

/// Table reference with a table function.
public struct FunctionTableReference: TableReferenceExpression {
  public var lateral: Bool

  public let function: TableFunction

  public let alias: FunctionAliasClause?

  public var tokens: JoinedTokenSequence {
    return .compacting(
      lateral ? SingleToken.lateral : nil,
      function,
      alias
    )
  }

  public init(lateral: Bool, function: TableFunction, alias: FunctionAliasClause? = nil) {
    self.lateral = lateral
    self.function = function
    self.alias = alias
  }
}

/// Table reference with `XMLTABLE` function.
public struct XMLTableReference: TableReferenceExpression {
  public var lateral: Bool

  public let function: XMLTableExpression

  public let alias: AliasClause?

  public var tokens: JoinedTokenSequence {
    return .compacting(
      lateral ? SingleToken.lateral : nil,
      function,
      alias
    )
  }

  public init(lateral: Bool, function: XMLTableExpression, alias: AliasClause? = nil) {
    self.lateral = lateral
    self.function = function
    self.alias = alias
  }
}

/// Select statement as a table reference with optional alias.
public struct SelectTableReference<Select>: TableReferenceExpression where Select: SelectStatement {
  public var lateral: Bool

  public let query: Parenthesized<Select>

  public let alias: AliasClause?

  public var tokens: JoinedTokenSequence {
    return .compacting(
      lateral ? SingleToken.lateral : nil,
      query,
      alias
    )
  }

  public init(
    lateral: Bool,
    query: Parenthesized<Select>,
    alias: AliasClause? = nil
  ) {
    self.lateral = lateral
    self.query = query
    self.alias = alias
  }

  public init(
    lateral: Bool,
    parenthesizing select: Select,
    alias: AliasClause? = nil
  ) {
    self.lateral = lateral
    self.query = select.parenthesized
    self.alias = alias
  }
}

/// Joined table as a table reference with an alias.
///
/// - Note: `AliasClause` of this type is not optional.
///         Any type conforming to `JoinedTableExpression` is available as a `TableReferenceExpression`
///         because protocol `JoinedTableExpression` inherits from `TableReferenceExpression`.
public struct JoinedTableAliasReference<JoinedTable>: TableReferenceExpression where JoinedTable: JoinedTableExpression {
  public let joinedTable: Parenthesized<JoinedTable>

  public let alias: AliasClause

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(joinedTable, alias)
  }

  public init(_ joinedTable: Parenthesized<JoinedTable>, alias: AliasClause) {
    self.joinedTable = joinedTable
    self.alias = alias
  }

  public init(parenthesizing joinedTable: JoinedTable, alias: AliasClause) {
    self.joinedTable = joinedTable.parenthesized
    self.alias = alias
  }
}
