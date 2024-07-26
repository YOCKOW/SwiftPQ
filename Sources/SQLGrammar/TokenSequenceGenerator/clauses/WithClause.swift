/* *************************************************************************************************
 WithClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// `WITH` clause that is described as `with_clause` in "gram.y".
public struct WithClause: Clause {
  public let recursive: Bool

  public let queries: CommonTableExpressionList

  public var tokens: JoinedTokenSequence {
    return .compacting(
      SingleToken.with,
      recursive ? SingleToken.recursive : nil,
      queries
    )
  }

  public init(recursive: Bool = false, queries: CommonTableExpressionList) {
    self.recursive = recursive
    self.queries = queries
  }
}
