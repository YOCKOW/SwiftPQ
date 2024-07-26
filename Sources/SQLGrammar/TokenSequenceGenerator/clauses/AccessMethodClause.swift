/* *************************************************************************************************
 AccessMethodClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause to specify access method described as `access_method_clause` in "gram.y".
public struct AccessMethodClause: Clause {
  public let methodName: Name

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken.using, methodName)
  }

  public init(methodName: Name) {
    self.methodName = methodName
  }
}

