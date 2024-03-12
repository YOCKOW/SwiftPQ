/* *************************************************************************************************
 Attributes.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing attributes which is expressed as `attrs` in "gram.y".
public struct Attributes: SQLTokenSequence {  
  public var names: NonEmptyList<AttributeName>

  public init(names: NonEmptyList<AttributeName>) {
    self.names = names
  }

  internal init(names: NonEmptyList<any _AttributeNameConvertible>) {
    self.init(names: names.map(\._attributeName))
  }

  public init(names: NonEmptyList<ColumnLabel>) {
    self.init(names: names.map({ $0 as any _AttributeNameConvertible }))
  }

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      dotJoiner,
      JoinedSQLTokenSequence(names, separator: dotJoiner)
    )
  }
}
