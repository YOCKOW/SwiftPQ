/* *************************************************************************************************
 WithinGroupClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private final class _WithinGroup: Segment {
  var tokens: Array<SQLToken> = [.within, .group]
  static let withinGroup: _WithinGroup = .init()
}

/// A clause that is described as `within_group_clause` in "gram.y".
public struct WithinGroupClause: Clause {
  public let orderBy: SortClause

  public var tokens: JoinedSQLTokenSequence {
    return _WithinGroup.withinGroup.followedBy(parenthesized: orderBy)
  }

  public init(orderBy: SortClause) {
    self.orderBy = orderBy
  }
}
