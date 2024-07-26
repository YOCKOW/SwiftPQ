/* *************************************************************************************************
 UpdateStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `Update` statement that is described as `UpdateStmt` in "gram.y".
@available(*, unavailable, message: "Unimplemented")
public struct UpdateStatement: Statement, PreparableStatement {
  public var tokens: JoinedTokenSequence {
    fatalError("Unimplemented.")
  }
}
