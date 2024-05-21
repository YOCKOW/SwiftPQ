/* *************************************************************************************************
 WhereClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A `WHERE` clause described as `where_clause` in "gram.y".
public struct WhereClause: Clause {
  public let condition: any GeneralExpression

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence([SingleToken(.where), condition] as [any SQLTokenSequence])
  }

  public init(condition: any GeneralExpression) {
    self.condition = condition
  }
}
