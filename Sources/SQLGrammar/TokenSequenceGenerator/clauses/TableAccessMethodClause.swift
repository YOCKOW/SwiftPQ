/* *************************************************************************************************
 TableAccessMethodClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause to specify table access method described as `table_access_method_clause` in "gram.y".
public struct TableAccessMethodClause: Clause {
  public let methodName: Name

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(SingleToken.using, methodName)
  }

  public init(methodName: Name) {
    self.methodName = methodName
  }
}
