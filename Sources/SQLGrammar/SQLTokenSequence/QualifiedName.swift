/* *************************************************************************************************
 QualifiedName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A qualified name that is described as `qualified_name` in "gram.y".
public struct QualifiedName: NameRepresentation {
  public let identifier: ColumnIdentifier

  public let indirection: Indirection?

  public init(identifier: ColumnIdentifier, indirection: Indirection? = nil) {
    self.identifier = identifier
    self.indirection = indirection
  }

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(SingleToken(identifier), indirection)
  }
}
