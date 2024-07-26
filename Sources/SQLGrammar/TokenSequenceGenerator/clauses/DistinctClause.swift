/* *************************************************************************************************
 DistinctClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// `DISTINCT [ON ( expression [, ...] ) ]` clause that is described as `distinct_clause` in "gram.y".
public struct DistinctClause: Clause {
  public let expressions: GeneralExpressionList?

  public var tokens: JoinedSQLTokenSequence {
    guard let expressions = self.expressions else {
      return JoinedSQLTokenSequence(SingleToken.distinct)
    }
    return JoinedSQLTokenSequence(
      SingleToken.distinct,
      SingleToken.on,
      expressions.parenthesized
    )
  }
}

/// Representation of a clause described as `opt_distinct_clause` in "gram.y".
public enum AllOrDistinctClause: Clause {
  case distinct(DistinctClause)
  case all

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    switch self {
    case .distinct(let distinctClause):
      return distinctClause.tokens
    case .all:
      return JoinedSQLTokenSequence(SingleToken.all)
    }
  }
}
