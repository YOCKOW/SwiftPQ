/* *************************************************************************************************
 InsertStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `INSERT INTO` statement that is described as `InsertStmt` in "gram.y".
@available(*, unavailable, message: "Unimplemented")
public struct InsertStatement: Statement, PreparableStatement {
  public var tokens: JoinedSQLTokenSequence {
    fatalError("Unimplemented.")
  }
}
