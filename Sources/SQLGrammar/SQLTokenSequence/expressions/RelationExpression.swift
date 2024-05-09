/* *************************************************************************************************
 RelationExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An expression described as `relation_expr` in "gram.y".
public struct RelationExpression: Expression {
  public let tableName: TableName

  public let includeDescendantTables: Bool?

  public var tokens: JoinedSQLTokenSequence {
    switch includeDescendantTables {
    case nil:
      return JoinedSQLTokenSequence(tableName)
    case true:
      return JoinedSQLTokenSequence([
        tableName,
        SQLToken.asterisk.asSequence,
      ] as [any SQLTokenSequence])
    case false:
      return JoinedSQLTokenSequence([
        SQLToken.only.asSequence,
        tableName,
      ] as [any SQLTokenSequence])
    default: // ????
      fatalError()
    }
  }

  public init(tableName: TableName, includeDescendantTables: Bool? = nil) {
    self.tableName = tableName
    self.includeDescendantTables = includeDescendantTables
  }
}
