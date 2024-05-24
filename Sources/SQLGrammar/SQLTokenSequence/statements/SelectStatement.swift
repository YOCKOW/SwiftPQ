/* *************************************************************************************************
 SelectStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of a `SELECT` statement or a similar statement,
/// that is described as `SelectStmt` in "gram.y".
public protocol SelectStatement: ParenthesizableStatement {}

/// Representation of `SELECT` statement without any parentheses,
/// that is described as `select_no_parens` in "gram.y".
public protocol BareSelectStatement: SelectStatement {}

/// A simple statement that is described as `simple_select` and
/// is compatible with `SELECT` clause.
public protocol SimpleSelectStatement: BareSelectStatement {}

// Represents `select_with_parens`.
extension Parenthesized: SelectStatement where EnclosedTokens: SelectStatement {}

// MARK: - SimpleSelectStatement a.k.a. simple_select implementations.

/// A `SELECT` statement that is one of `simple_select`(`SimpleSelectStatement`).
public struct SimpleSelectQuery: SimpleSelectStatement {
  public enum DuplicateRowStrategy: SQLTokenSequence {
    /// A specifier to return all candidate rows.
    /// Grammatically this represents `opt_all_clause` in "gram.y".
    case all

    case distinct(DistinctClause)

    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .all:
        return JoinedSQLTokenSequence(SingleToken(.all))
      case .distinct(let distinctClause):
        return distinctClause.tokens
      }
    }
  }

  public let duplicateRowStrategy: DuplicateRowStrategy?

  public let targets: TargetList?

  public let intoClause: IntoClause?

  public let fromClause: FromClause?

  public let whereClause: WhereClause?

  public let groupClause: GroupClause?

  public let havingClause: HavingClause?

  public let windowClause: WindowClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      SingleToken(.select),
      duplicateRowStrategy,
      targets,
      intoClause,
      fromClause,
      whereClause,
      groupClause,
      havingClause,
      windowClause
    )
  }

  private init(
    duplicateRowStrategy: DuplicateRowStrategy?,
    targets: TargetList?,
    intoClause: IntoClause?,
    fromClause: FromClause?,
    whereClause: WhereClause?,
    groupClause: GroupClause?,
    havingClause: HavingClause?,
    windowClause: WindowClause?
  ) {
    self.duplicateRowStrategy = duplicateRowStrategy
    self.targets = targets
    self.intoClause = intoClause
    self.fromClause = fromClause
    self.whereClause = whereClause
    self.groupClause = groupClause
    self.havingClause = havingClause
    self.windowClause = windowClause
  }

  public init(
    targets: TargetList? = nil,
    into intoClause: IntoClause? = nil,
    from fromClause: FromClause? = nil,
    where whereClause: WhereClause? = nil,
    group groupClause: GroupClause? = nil,
    having havingClause: HavingClause? = nil,
    window windowClause: WindowClause? = nil
  ) {
    self.init(
      duplicateRowStrategy: nil,
      targets: targets,
      intoClause: intoClause,
      fromClause: fromClause,
      whereClause: whereClause,
      groupClause: groupClause,
      havingClause: havingClause,
      windowClause: windowClause
    )
  }

  /// Creates `SELECT ALL ...` statement.
  public static func selectAllRows(
    targets: TargetList? = nil,
    into intoClause: IntoClause? = nil,
    from fromClause: FromClause? = nil,
    where whereClause: WhereClause? = nil,
    group groupClause: GroupClause? = nil,
    having havingClause: HavingClause? = nil,
    window windowClause: WindowClause? = nil
  ) -> SimpleSelectQuery {
    return SimpleSelectQuery(
      duplicateRowStrategy: .all,
      targets: targets,
      intoClause: intoClause,
      fromClause: fromClause,
      whereClause: whereClause,
      groupClause: groupClause,
      havingClause: havingClause,
      windowClause: windowClause
    )
  }

  /// Creates `SELECT DISTINCT [ON ...] ...` statement.
  public static func selectDistinctRows(
    on distinctClause: DistinctClause,
    targets: TargetList, // nil not allowed!
    into intoClause: IntoClause? = nil,
    from fromClause: FromClause? = nil,
    where whereClause: WhereClause? = nil,
    group groupClause: GroupClause? = nil,
    having havingClause: HavingClause? = nil,
    window windowClause: WindowClause? = nil
  ) -> SimpleSelectQuery {
    return SimpleSelectQuery(
      duplicateRowStrategy: .distinct(distinctClause),
      targets: targets,
      intoClause: intoClause,
      fromClause: fromClause,
      whereClause: whereClause,
      groupClause: groupClause,
      havingClause: havingClause,
      windowClause: windowClause
    )
  }
}

extension ValuesClause: SimpleSelectStatement {}

/// A `TABLE` command that is described as `TABLE relation_expr` in "gram.y".
public struct TableCommandSyntax: SimpleSelectStatement {
  public let relation: RelationExpression

  public var name: TableName {
    return relation.tableName
  }

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.table), relation)
  }

  public init(_ relation: RelationExpression) {
    self.relation = relation
  }

  public init(tableName: TableName, includeDescendantTables: Bool? = nil) {
    self.relation = RelationExpression(
      tableName: tableName,
      includeDescendantTables: includeDescendantTables
    )
  }
}

// MARK: END OF SimpleSelectStatement a.k.a. simple_select implementations. -
