/* *************************************************************************************************
 DeleteStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `DELETE` statement that is described as `DeleteStmt` in "gram.y".
@available(*, unavailable, message: "Unimplemented")
public struct DeleteStatement: Statement, PreparableStatement {
  public var tokens: JoinedTokenSequence {
    fatalError("Unimplemented.")
  }
}
