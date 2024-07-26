/* *************************************************************************************************
 RelationExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An expression described as `relation_expr` in "gram.y".
public struct RelationExpression: Expression, ExpressibleByStringLiteral {
  public let tableName: TableName

  public let includeDescendantTables: Bool?

  public var tokens: JoinedSQLTokenSequence {
    switch includeDescendantTables {
    case nil:
      return JoinedSQLTokenSequence(tableName)
    case true:
      return JoinedSQLTokenSequence([
        tableName,
        Token.asterisk.asSequence,
      ] as [any TokenSequenceGenerator])
    case false:
      return JoinedSQLTokenSequence([
        Token.only.asSequence,
        tableName,
      ] as [any TokenSequenceGenerator])
    default: // ????
      fatalError()
    }
  }

  public init(_ tableName: TableName, includeDescendantTables: Bool? = nil) {
    self.tableName = tableName
    self.includeDescendantTables = includeDescendantTables
  }

  @inlinable
  public init(stringLiteral value: String) {
    self.init(TableName(stringLiteral: value))
  }
}
