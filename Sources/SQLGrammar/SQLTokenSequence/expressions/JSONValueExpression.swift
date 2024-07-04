/* *************************************************************************************************
 JSONValueExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of JSON value, described as `json_value_expr` in "gram.y".
public struct JSONValueExpression: Expression {
  public let value: any GeneralExpression

  public let format: JSONFormatClause?

  public var tokens: JoinedSQLTokenSequence {
    JoinedSQLTokenSequence.compacting([value, format] as [(any SQLTokenSequence)?])
  }

  public init(value: any GeneralExpression, format: JSONFormatClause? = nil) {
    self.value = value
    self.format = format
  }
}
