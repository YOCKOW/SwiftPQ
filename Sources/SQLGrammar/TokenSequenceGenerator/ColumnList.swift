/* *************************************************************************************************
 ColumnList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element of `ColumnList`. Described as `columnElem` in "gram.y".
public struct ColumnListElement: LosslessTokenConvertible, ExpressibleByStringLiteral, Sendable {
  public let name: ColumnIdentifier

  @inlinable
  public var token: Token {
    return name.token
  }

  public init(_ name: ColumnIdentifier) {
    self.name = name
  }

  public init?(_ token: Token) {
    guard let id = ColumnIdentifier(token) else { return nil }
    self.init(id)
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(ColumnIdentifier(stringLiteral: value))
  }
}

/// A list of column identifiers. Described as `columnList` in "gram.y".
public struct ColumnList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public let names: NonEmptyList<ColumnListElement>

  public var tokens: JoinedTokenSequence {
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
public enum OptionalColumnList: TokenSequenceGenerator,
                                InitializableWithNonEmptyList,
                                ExpressibleByNilLiteral,
                                ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = ColumnListElement
  public typealias ArrayLiteralElement = ColumnListElement

  case none
  case some(ColumnList)

  public struct Tokens: Sequence {
    public struct Iterator: IteratorProtocol {
      public typealias Element = Token
      private var _iterator: ColumnList.Tokens.Iterator?
      fileprivate init(_ iterator: ColumnList.Tokens.Iterator?) {
        self._iterator = iterator
      }
      public mutating func next() -> Token? { return _iterator?.next() }
    }
    private let _optionalColumnList: OptionalColumnList
    fileprivate init(_ optionalColumnList: OptionalColumnList) {
      self._optionalColumnList = optionalColumnList
    }
    public func makeIterator() -> Iterator {
      guard case .some(let list) = _optionalColumnList else { return Iterator(nil) }
      return Iterator(list.parenthesized.makeIterator())
    }
  }

  public var tokens: Tokens {
    return Tokens(self)
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
