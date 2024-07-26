/* *************************************************************************************************
 FilterClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that is described as `filter_clause` in "gram.y".
public struct FilterClause: Clause {
  public let predicate: any GeneralExpression

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.filter).followedBy(parenthesized: JoinedSQLTokenSequence([
      SingleToken(.where),
      predicate
    ] as [any TokenSequenceGenerator]))
  }

  public init(where predicate: any GeneralExpression) {
    self.predicate = predicate
  }
}
