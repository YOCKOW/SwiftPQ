/* *************************************************************************************************
 AnyName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a name that is described as `any_name` in "gram.y".
public struct AnyName: NameRepresentation {
  public let columnIdentifier: ColumnIdentifier

  public let attributes: Attributes?

  public init(columnIdentifier: ColumnIdentifier, attributes: Attributes? = nil) {
    self.columnIdentifier = columnIdentifier
    self.attributes = attributes
  }

  public var tokens: JoinedSQLTokenSequence {
    // Note: `Attributes` include leading period!
    return JoinedSQLTokenSequence.compacting(SingleToken(columnIdentifier), attributes)
  }
}
