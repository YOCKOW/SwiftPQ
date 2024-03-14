/* *************************************************************************************************
 AnyName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a name that is described as `any_name` in "gram.y".
public struct AnyName: NameRepresentation {
  public let identifier: ColumnIdentifier

  public let attributes: Attributes?

  public init(identifier: ColumnIdentifier, attributes: Attributes? = nil) {
    self.identifier = identifier
    self.attributes = attributes
  }

  public var tokens: JoinedSQLTokenSequence {
    // Note: `Attributes` include leading period!
    return JoinedSQLTokenSequence.compacting(SingleToken(identifier), attributes)
  }
}
