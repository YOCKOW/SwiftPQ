/* *************************************************************************************************
 MergeStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `MERGE INTO` statement that is described as `MergeStmt` in "gram.y".
@available(*, unavailable, message: "Unimplemented")
public struct MergeStatement: Statement, PreparableStatement {
  public var tokens: JoinedSQLTokenSequence {
    fatalError("Unimplemented.")
  }
}
