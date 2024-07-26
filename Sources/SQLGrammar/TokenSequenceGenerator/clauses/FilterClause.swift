/* *************************************************************************************************
 FilterClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that is described as `filter_clause` in "gram.y".
public struct FilterClause: Clause {
  public let predicate: any GeneralExpression

  public var tokens: JoinedTokenSequence {
    return SingleToken.filter.followedBy(parenthesized: JoinedTokenSequence([
      SingleToken.where,
      predicate
    ] as [any TokenSequenceGenerator]))
  }

  public init(where predicate: any GeneralExpression) {
    self.predicate = predicate
  }
}
