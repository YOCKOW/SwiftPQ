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

/// Representation of `opt_column_list` in "gram.y".
///
/// This should not be represented by `Optional<ColumnList>`
/// because `opt_column_list` must emit parenthesized `columnList` if it has a value.
public enum OptionalColumnList: SQLTokenSequence,
                                InitializableWithNonEmptyList,
                                ExpressibleByNilLiteral,
                                ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = ColumnListElement
  public typealias ArrayLiteralElement = ColumnListElement

  case none
  case some(ColumnList)

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken
    private var _iterator: ColumnList.Iterator?
    fileprivate init(_ iterator: ColumnList.Iterator?) {
      self._iterator = iterator
    }
    public mutating func next() -> SQLToken? { return _iterator?.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
    guard case .some(let list) = self else { return Iterator(nil) }
    return Iterator(list.parenthesized.makeIterator())
  }

  @inlinable
  public var isNil: Bool {
    switch self {
    case .none:
      return true
    case .some:
      return false
    }
  }

  @inlinable
  public var columnList: ColumnList? {
    guard case .some(let list) = self else { return nil }
    return list
  }

  public init(nilLiteral: ()) {
    self = .none
  }

  public init(_ list: NonEmptyList<ColumnListElement>) {
    self = .some(ColumnList(list))
  }
}
