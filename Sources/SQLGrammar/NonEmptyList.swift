/* *************************************************************************************************
 NonEmptyList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a collection of `Item`s that is guaranteed to be non-empty.
public struct NonEmptyList<Item>: BidirectionalCollection, MutableCollection {
  public typealias Element = Item

  public private(set) var items: Array<Item>

  public init(item: Item) {
    self.items = [item]
  }

  public init?<C>(items: C) where C: Collection, C.Element == Item {
    if items.isEmpty {
      return nil
    }
    self.items = Array(items)
  }

  public typealias Iterator = Array<Item>.Iterator

  @inlinable
  public func makeIterator() -> Iterator {
    return items.makeIterator()
  }

  public typealias Index = Array<Item>.Index

  @inlinable
  public var startIndex: Index {
    return items.startIndex
  }

  @inlinable
  public var endIndex: Index {
    return items.endIndex
  }

  @inlinable
  public func index(after i: Index) -> Index {
    return items.index(after: i)
  }

  @inlinable
  public func index(before i: Index) -> Index {
    return items.index(before: i)
  }

  public subscript(position: Index) -> Element {
    @inlinable get {
      return items[position]
    }
    set {
      items[position] = newValue
    }
  }

  @inlinable
  public var count: Int {
    return items.count
  }

  @inlinable
  public var isEmpty: Bool {
    assert(!items.isEmpty)
    return false
  }

  @inlinable
  public var first: Element {
    assert(!items.isEmpty)
    return items.first.unsafelyUnwrapped
  }

  @inlinable
  public var last: Element {
    assert(!items.isEmpty)
    return items.last.unsafelyUnwrapped
  }

  public mutating func append(_ item: Item) {
    items.append(item)
  }

  public mutating func append<S>(contentsOf newItems: S) where S: Sequence, S.Element == Item {
    items.append(contentsOf: newItems)
  }

  @inlinable
  public func map<T>(_ transform: (Element) throws -> T) rethrows -> NonEmptyList<T> {
    return NonEmptyList<T>(items: try items.map(transform))!
  }
}

extension NonEmptyList: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Item

  public init(arrayLiteral elements: Item...) {
    guard let list = Self.init(items: elements) else {
      fatalError("Items must not be empty.")
    }
    self = list
  }
}

public protocol InitializableWithNonEmptyList {
  associatedtype NonEmptyListElement
  init(_ list: NonEmptyList<NonEmptyListElement>)
}
extension InitializableWithNonEmptyList {
  public init(_ element: NonEmptyListElement) {
    self.init(NonEmptyList<NonEmptyListElement>(item: element))
  }
}
extension InitializableWithNonEmptyList where Self: ExpressibleByArrayLiteral,
                                              Self.NonEmptyListElement == Self.ArrayLiteralElement {
  public init(arrayLiteral elements: Self.NonEmptyListElement...) {
    guard let nonEmptyList = NonEmptyList(items: elements) else {
      fatalError("\(Self.self): Missing elements.")
    }
    self.init(nonEmptyList)
  }
}

