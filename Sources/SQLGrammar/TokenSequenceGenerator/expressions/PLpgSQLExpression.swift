/* *************************************************************************************************
 PLpgSQLExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A PL/pgSQL expression described as `PLpgSQL_Expr` in "gram.y".
public struct PLpgSQLExpression: Expression {
  public let allOrDistinct: AllOrDistinctClause?

  public let targets: TargetList?

  public let fromClause: FromClause?

  public let whereClause: WhereClause?

  public let groupClause: GroupClause?

  public let havingClause: HavingClause?

  public let windowClause: WindowClause?

  public let orderBy: SortClause?

  public let limit: SelectLimitClause?

  public let forLocking: LockingClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      allOrDistinct,
      targets,
      fromClause,
      whereClause,
      groupClause,
      havingClause,
      windowClause,
      orderBy,
      limit,
      forLocking
    )
  }

  public init(
    allOrDistinct: AllOrDistinctClause? = nil,
    targets: TargetList? = nil,
    from fromClause: FromClause? = nil,
    where whereClause: WhereClause? = nil,
    group groupClause: GroupClause? = nil,
    having havingClause: HavingClause? = nil,
    window windowClause: WindowClause? = nil,
    orderBy: SortClause? = nil,
    limit: SelectLimitClause? = nil,
    forLocking: LockingClause? = nil
  ) {
    self.allOrDistinct = allOrDistinct
    self.targets = targets
    self.fromClause = fromClause
    self.whereClause = whereClause
    self.groupClause = groupClause
    self.havingClause = havingClause
    self.windowClause = windowClause
    self.orderBy = orderBy
    self.limit = limit
    self.forLocking = forLocking
  }
}
