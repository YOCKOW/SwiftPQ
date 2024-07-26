/* *************************************************************************************************
 WhereClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A `WHERE` clause described as `where_clause` in "gram.y".
public struct WhereClause: Clause {
  public let condition: any GeneralExpression

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([SingleToken.where, condition] as [any TokenSequenceGenerator])
  }

  public init(condition: any GeneralExpression) {
    self.condition = condition
  }
}

/// A `WHERE` clause described as `OptWhereClause` in "gram.y".
public struct WhereParenthesizedExpressionClause: Clause {
  public let predicate: any GeneralExpression

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(SingleToken.where, predicate._asAny.parenthesized)
  }

  public init(predicate: any GeneralExpression) {
    self.predicate = predicate
  }
}
