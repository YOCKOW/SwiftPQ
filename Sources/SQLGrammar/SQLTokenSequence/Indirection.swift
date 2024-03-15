/* *************************************************************************************************
 Indirection.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing `indirection`.
public struct Indirection: SQLTokenSequence {
  @dynamicMemberLookup
  public struct List: BidirectionalCollection, MutableCollection {
    /// A type representing an element of `Indirection.List` that is described as `indirection_el` in "gram.y".
    public enum Element: SQLTokenSequence {
      case attributeName(AttributeName)
      case any
      case `subscript`(any GeneralExpression)
      case slice(lowerBound: (any GeneralExpression)?, upperBound: (any GeneralExpression)?)

      public var tokens: JoinedSQLTokenSequence {
        switch self {
        case .attributeName(let attributeName):
          return JoinedSQLTokenSequence(dotJoiner, attributeName)
        case .any:
          return JoinedSQLTokenSequence(dotJoiner, SingleToken(.asterisk))
        case .subscript(let expression):
          return JoinedSQLTokenSequence(
            SingleToken(.joiner),
            SingleToken(.leftSquareBracket),
            AnySQLTokenSequence(expression),
            SingleToken(.rightSquareBracket)
          )
        case .slice(let lowerBound, let upperBound):
          return JoinedSQLTokenSequence.compacting(
            SingleToken(.joiner),
            SingleToken(.leftSquareBracket),
            lowerBound.map({ AnySQLTokenSequence($0) }),
            SingleToken(.colon),
            upperBound.map({ AnySQLTokenSequence($0) }),
            SingleToken(.rightSquareBracket)
          )
        }
      }
    }

    public typealias BaseList = NonEmptyList<Element>

    public typealias Index = BaseList.Index

    public typealias Iterator = BaseList.Iterator

    public var elements: BaseList

    public init(_ elements: NonEmptyList<Element>) {
      self.elements = elements
    }

    @inlinable
    public subscript<T>(dynamicMember keyPath: KeyPath<BaseList, T>) -> T {
      return elements[keyPath: keyPath]
    }

    @inlinable
    public func makeIterator() -> Iterator {
      return elements.makeIterator()
    }

    @inlinable
    public var startIndex: Index { return elements.startIndex }

    @inlinable
    public var endIndex: Index { return elements.endIndex }

    @inlinable
    public func index(after i: Index) -> Index { return elements.index(after: i) }

    @inlinable
    public func index(before i: Index) -> Index { return elements.index(before: i) }

    @inlinable
    public subscript(position: Index) -> Element {
      get { return elements[position] }
      set { elements[position] = newValue }
    }
  }

  public var list: List

  public init(_ list: List) {
    self.list = list
  }

  public var tokens: JoinedSQLTokenSequence {
    return list.joined()
  }
}

extension Indirection.List: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Indirection.List.Element

  public init(arrayLiteral elements: ArrayLiteralElement...) {
    guard let nonEmptyList = NonEmptyList<ArrayLiteralElement>(items: elements) else {
      fatalError("List must not be empty.")
    }
    self.init(nonEmptyList)
  }
}

extension Indirection: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Indirection.List.Element

  public init(arrayLiteral elements: ArrayLiteralElement...) {
    guard let nonEmptyList = NonEmptyList<ArrayLiteralElement>(items: elements) else {
      fatalError("List must not be empty.")
    }
    self.init(List(nonEmptyList))
  }
}
