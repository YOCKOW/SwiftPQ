/* *************************************************************************************************
 InheritClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that specifies a list of tables from which the new table automatically inherits
///  all columns. This is described as `OptInherit` in "gram.y".
public struct InheritClause: Clause {
  public var parentTables: QualifiedNameList<TableName>

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken.inherits, parentTables.parenthesized)
  }

  public init(_ parentTables: QualifiedNameList<TableName>) {
    self.parentTables = parentTables
  }
}
