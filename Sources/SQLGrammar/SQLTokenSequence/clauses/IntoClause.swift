/* *************************************************************************************************
 IntoClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// `INTO ...` clause used in `SELECT` statement.
public struct IntoClause: SQLTokenSequence {
  public let name: TemporaryTableName

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.into), name)
  }

  public init(_ name: TemporaryTableName) {
    self.name = name
  }
}
