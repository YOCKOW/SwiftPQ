/* *************************************************************************************************
 ColumnList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element of `ColumnList`. Described as `columnElem` in "gram.y".
public struct ColumnListElement: LosslessTokenConvertible, ExpressibleByStringLiteral {
  public let name: ColumnIdentifier

  @inlinable
  public var token: SQLToken {
    return name.token
  }

  public init(_ name: ColumnIdentifier) {
    self.name = name
  }

  public init?(_ token: SQLToken) {
    guard let id = ColumnIdentifier(token) else { return nil }
    self.init(id)
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(ColumnIdentifier(stringLiteral: value))
  }
}

/// A list of column identifiers. Described as `columnList` in "gram.y".
public struct ColumnList: SQLTokenSequence, ExpressibleByArrayLiteral {
  public let names: NonEmptyList<ColumnListElement>

  public var tokens: JoinedSQLTokenSequence {
    return names.joinedByCommas()
  }

  public init(_ names: NonEmptyList<ColumnListElement>) {
    self.names = names
  }

  public init(arrayLiteral elements: ColumnListElement...) {
    guard let nonEmptyElements = NonEmptyList<ColumnListElement>(items: elements) else {
      fatalError("\(Self.self): No elements?!")
    }
    self.init(nonEmptyElements)
  }
}
