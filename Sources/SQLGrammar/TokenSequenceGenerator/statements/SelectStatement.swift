/* *************************************************************************************************
 SelectStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of a `SELECT` statement or a similar statement,
/// that is described as `SelectStmt` in "gram.y".
public protocol SelectStatement: ParenthesizableStatement, ParenthesizablePreparableStatement {}

/// Representation of `SELECT` statement without any parentheses,
/// that is described as `select_no_parens` in "gram.y".
public protocol BareSelectStatement: SelectStatement {}

/// A simple statement that is described as `simple_select` and
/// is compatible with `SELECT` clause.
public protocol SimpleSelectStatement: BareSelectStatement {}

// Represents `select_with_parens`.
extension Parenthesized: SelectStatement where EnclosedTokens: SelectStatement {}

/// A type-erasure for `Parenthesized<SelectStatement>`(`select`).
internal struct AnyParenthesizedSelectStatement: TokenSequence {
  let parenthesizedSelectStatement: any SelectStatement

  struct Iterator: IteratorProtocol {
    typealias Element = Token
    private let _iterator: AnyTokenSequenceIterator
    func next() -> Token? { _iterator.next() }
    fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
  }
  typealias Tokens = Self

  func makeIterator() -> Iterator {
    return Iterator(parenthesizedSelectStatement._anyIterator)
  }

  func subquery<T>(as selectStatementType: T.Type) -> T? where T: SelectStatement {
    guard case let parenthesizedT as Parenthesized<T> = parenthesizedSelectStatement else {
      return nil
    }
    return parenthesizedT.enclosedTokens
  }

  init<T>(_ parenthesizedSelectStatement: Parenthesized<T>) where T: SelectStatement {
    self.parenthesizedSelectStatement = parenthesizedSelectStatement
  }

  init<T>(parenthesizing selectStatement: T) where T: SelectStatement {
    self.parenthesizedSelectStatement = selectStatement.parenthesized
  }
}

// MARK: - SimpleSelectStatement a.k.a. simple_select implementations.

/// A `SELECT` statement that is one of `simple_select`(`SimpleSelectStatement`).
public struct SimpleSelectQuery: SimpleSelectStatement {
  public enum DuplicateRowStrategy: TokenSequenceGenerator {
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
      tableName,
      includeDescendantTables: includeDescendantTables
    )
  }
}

/// A kind of select statement that consists of [combined queries](https://www.postgresql.org/docs/16/queries-union.html).
public struct CombinedSelectQuery: SimpleSelectStatement {
  public enum SetOperation: LosslessTokenConvertible {
    case union
    case intersect
    case except

    public var token: Token {
      switch self {
      case .union:
        return .union
      case .intersect:
        return .intersect
      case .except:
        return .except
      }
    }

    public init?(_ token: Token) {
      switch token {
      case .union:
        self = .union
      case .intersect:
        self = .intersect
      case .except:
        self = .except
      default:
        return nil
      }
    }
  }

  public let leftQuery: SelectClause

  public let operation: SetOperation

  public let quantifier: SetQuantifier?

  public let rightQuery: SelectClause

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      leftQuery,
      operation.asSequence,
      quantifier?.asSequence,
      rightQuery
    )
  }

  public init(
    _ leftQuery: SelectClause,
    _ operation: SetOperation,
    _ quantifier: SetQuantifier? = nil,
    _ rightQuery: SelectClause
  ) {
    self.leftQuery = leftQuery
    self.operation = operation
    self.quantifier = quantifier
    self.rightQuery = rightQuery
  }
}
extension SelectClause {
  public func union(
    _ quantifier: SetQuantifier? = nil,
    _ other: SelectClause
  ) -> CombinedSelectQuery {
    return CombinedSelectQuery(self, .union, quantifier, other)
  }

  public func intersect(
    _ quantifier: SetQuantifier? = nil,
    _ other: SelectClause
  ) -> CombinedSelectQuery {
    return CombinedSelectQuery(self, .intersect, quantifier, other)
  }

  public func except(
    _ quantifier: SetQuantifier? = nil,
    _ other: SelectClause
  ) -> CombinedSelectQuery {
    return CombinedSelectQuery(self, .except, quantifier, other)
  }
}

// MARK: END OF SimpleSelectStatement a.k.a. simple_select implementations. -


/// One of `select_no_parens`(`BareSelectStatement`) statement that
/// starts with optional `with_clause`(`WithClause`) and
/// contains trailing various parameters such as `sort_clause`(`SortClause`).
public struct FullyFunctionalSelectQuery: BareSelectStatement {
  private enum _Pattern {
    enum _TrailingParameters: Segment {
      case sortClause(SortClause)

      case optSortClause_lockingClause_optSelectLimitClause(
        SortClause?,
        LockingClause,
        SelectLimitClause?
      )
      
      case optSortClause_selectLimitClause_optLockingClause(
        SortClause?,
        SelectLimitClause,
        LockingClause?
      )

      var tokens: JoinedSQLTokenSequence {
        switch self {
        case .sortClause(let sortClause):
          return sortClause.tokens
        case .optSortClause_lockingClause_optSelectLimitClause(
          let sortClause,
          let lockingClause,
          let selectLimitClause
        ):
          return .compacting(sortClause, lockingClause, selectLimitClause)
        case .optSortClause_selectLimitClause_optLockingClause(
          let sortClause,
          let selectLimitClause,
          let lockingClause
        ):
          return .compacting(sortClause, selectLimitClause, lockingClause)
        }
      }

      var sortClause: SortClause? {
        switch self {
        case .sortClause(let sortClause):
          return sortClause
        case .optSortClause_lockingClause_optSelectLimitClause(let sortClause, _, _):
          return sortClause
        case .optSortClause_selectLimitClause_optLockingClause(let sortClause, _, _):
          return sortClause
        }
      }

      var lockingClause: LockingClause? {
        switch self {
        case .sortClause:
          return nil
        case .optSortClause_lockingClause_optSelectLimitClause(_, let lockingClause, _):
          return lockingClause
        case .optSortClause_selectLimitClause_optLockingClause(_, _, let lockingClause):
          return lockingClause
        }
      }

      var limitClause: SelectLimitClause? {
        switch self {
        case .sortClause:
          return nil
        case .optSortClause_lockingClause_optSelectLimitClause(_, _, let selectLimitClause):
          return selectLimitClause
        case .optSortClause_selectLimitClause_optLockingClause(_, let selectLimitClause, _):
          return selectLimitClause
        }
      }
    }

    case selectClause(SelectClause, parameters: _TrailingParameters)

    case withClause(WithClause, selectClause: SelectClause, parameters: _TrailingParameters?)
  }

  private let _pattern: _Pattern

  public var tokens: JoinedSQLTokenSequence {
    switch _pattern {
    case .selectClause(let selectClause, let parameters):
      return JoinedSQLTokenSequence(selectClause, parameters)
    case .withClause(let withClause, let selectClause, let parameters):
      return .compacting(withClause, selectClause, parameters)
    }
  }

  public var with: WithClause? {
    guard case .withClause(let withClause, _, _) = _pattern else {
      return nil
    }
    return withClause
  }

  public var select: SelectClause {
    switch _pattern {
    case .selectClause(let selectClause, _):
      return selectClause
    case .withClause(_, let selectClause, _):
      return selectClause
    }
  }

  private var _trailingParameters: _Pattern._TrailingParameters? {
    switch _pattern {
    case .selectClause(_, let parameters):
      return parameters
    case .withClause(_, _, let parameters):
      return parameters
    }
  }

  public var orderBy: SortClause? {
    return _trailingParameters?.sortClause
  }

  public var forLocking: LockingClause? {
    return _trailingParameters?.lockingClause
  }

  public var limit: SelectLimitClause? {
    return _trailingParameters?.limitClause
  }

  private init(_pattern: _Pattern) {
    self._pattern = _pattern
  }

  public init(_ selectClause: SelectClause, orderBy sortClause: SortClause) {
    self.init(_pattern: .selectClause(selectClause, parameters: .sortClause(sortClause)))
  }

  public init(
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause? = nil,
    forLocking lockingClause: LockingClause,
    limit: SelectLimitClause? = nil
  ) {
    self.init(_pattern: .selectClause(
      selectClause,
      parameters: .optSortClause_lockingClause_optSelectLimitClause(
        sortClause,
        lockingClause,
        limit
      )
    ))
  }

  public init(
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause? = nil,
    limit: SelectLimitClause,
    forLocking lockingClause: LockingClause? = nil
  ) {
    self.init(_pattern: .selectClause(
      selectClause,
      parameters: .optSortClause_selectLimitClause_optLockingClause(
        sortClause,
        limit,
        lockingClause
      )
    ))
  }

  public init(with withClause: WithClause, _ selectClause: SelectClause) {
    self.init(_pattern: .withClause(withClause, selectClause: selectClause, parameters: nil))
  }

  public init(
    with withClause: WithClause,
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause
  ) {
    self.init(_pattern: .withClause(
      withClause,
      selectClause: selectClause,
      parameters: .sortClause(sortClause)
    ))
  }

  public init(
    with withClause: WithClause,
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause? = nil,
    forLocking lockingClause: LockingClause,
    limit: SelectLimitClause? = nil
  ) {
    self.init(_pattern: .withClause(
      withClause,
      selectClause: selectClause,
      parameters: .optSortClause_lockingClause_optSelectLimitClause(
        sortClause,
        lockingClause,
        limit
      )
    ))
  }

  public init(
    with withClause: WithClause,
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause? = nil,
    limit: SelectLimitClause,
    forLocking lockingClause: LockingClause? = nil
  ) {
    self.init(_pattern: .withClause(
      withClause,
      selectClause: selectClause,
      parameters: .optSortClause_selectLimitClause_optLockingClause(
        sortClause,
        limit,
        lockingClause
      )
    ))
  }
}

extension WithClause {
  @inlinable
  public func select(_ selectClause: SelectClause) -> FullyFunctionalSelectQuery {
    return FullyFunctionalSelectQuery(with: self, selectClause)
  }

  @inlinable
  public func select(
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause
  ) -> FullyFunctionalSelectQuery {
    return FullyFunctionalSelectQuery(with: self, selectClause, orderBy: sortClause)
  }

  @inlinable
  public func select(
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause? = nil,
    forLocking lockingClause: LockingClause,
    limit: SelectLimitClause? = nil
  ) -> FullyFunctionalSelectQuery {
    return FullyFunctionalSelectQuery(
      with: self,
      selectClause,
      orderBy: sortClause,
      forLocking: lockingClause,
      limit: limit
    )
  }

  @inlinable
  public func select(
    _ selectClause: SelectClause,
    orderBy sortClause: SortClause? = nil,
    limit: SelectLimitClause,
    forLocking lockingClause: LockingClause? = nil
  ) -> FullyFunctionalSelectQuery {
    return FullyFunctionalSelectQuery(
      with: self,
      selectClause,
      orderBy: sortClause,
      limit: limit,
      forLocking: lockingClause
    )
  }
}
