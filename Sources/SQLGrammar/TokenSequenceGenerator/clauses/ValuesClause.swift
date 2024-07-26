/* *************************************************************************************************
 ValuesClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// `VALUES` clause that is described as `values_clause` in "gram.y".
public struct ValuesClause: Clause {
  public typealias ColumnList = GeneralExpressionList

  public let rows: NonEmptyList<ColumnList>

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(
      SingleToken.values,
      rows.map({ $0.parenthesized }).joinedByCommas()
    )
  }

  public init(_ rows: NonEmptyList<ColumnList>) {
    self.rows = rows
  }
}
