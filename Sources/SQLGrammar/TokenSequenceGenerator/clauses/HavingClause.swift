/* *************************************************************************************************
 HavingClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// `HAVING` clause that is described as `having_clause` in "gram.y".
public struct HavingClause: Clause {
  public let predicate: any GeneralExpression

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence([SingleToken.having, predicate])
  }

  public init(predicate: any GeneralExpression) {
    self.predicate = predicate
  }
}
