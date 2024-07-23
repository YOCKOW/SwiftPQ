/* *************************************************************************************************
 JSONValueExpressionList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A list of JSON values, described as `json_value_expr_list` in "gram.y".
public struct JSONValueExpressionList: SQLTokenSequence {
  public let values: NonEmptyList<JSONValueExpression>

  public var tokens: JoinedSQLTokenSequence {
    return values.joinedByCommas()
  }

  public init(values: NonEmptyList<JSONValueExpression>) {
    self.values = values
  }
}
