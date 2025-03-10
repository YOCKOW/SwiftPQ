/* *************************************************************************************************
 Indirection.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing `indirection`.
public struct Indirection: TokenSequenceGenerator {
  @dynamicMemberLookup
  public struct List: BidirectionalCollection, MutableCollection, Sendable {
    /// A type representing an element of `Indirection.List` that is described as `indirection_el` in "gram.y".
    public enum Element: TokenSequenceGenerator {
      case attributeName(AttributeName)
      case any
      case `subscript`(any GeneralExpression )
      case slice(
        lowerBound: (any GeneralExpression )?,
        upperBound: (any GeneralExpression )?
      )

      public var tokens: JoinedTokenSequence {
        switch self {
        case .attributeName(let attributeName):
          return JoinedTokenSequence(dotJoiner, attributeName)
        case .any:
          return JoinedTokenSequence(dotJoiner, SingleToken.asterisk)
        case .subscript(let expression):
          return JoinedTokenSequence(
            SingleToken.joiner,
            SingleToken.leftSquareBracket,
            AnyTokenSequence(expression),
            SingleToken.rightSquareBracket
          )
        case .slice(let lowerBound, let upperBound):
          return JoinedTokenSequence.compacting(
            SingleToken.joiner,
            SingleToken.leftSquareBracket,
            lowerBound.map({ AnyTokenSequence($0) }),
            SingleToken.colon,
            upperBound.map({ AnyTokenSequence($0) }),
            SingleToken.rightSquareBracket
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
    public var first: Element {
      return elements.first
    }

    @inlinable
    public var last: Element {
      return elements.last
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
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> NonEmptyList<T> {
      return try elements.map(transform)
    }

    @inlinable
    public subscript(position: Index) -> Element {
      get { return elements[position] }
      set { elements[position] = newValue }
    }

    @inlinable
    public mutating func append(_ newElement: Element) {
      elements.append(newElement)
    }

    @inlinable
    public mutating func append<S>(contentsOf newElements: S) where S: Sequence, S.Element == Element {
      elements.append(contentsOf: newElements)
    }
  }

  public var list: List

  public init(_ list: List) {
    self.list = list
  }

  public var tokens: JoinedTokenSequence {
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
