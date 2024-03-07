/* *************************************************************************************************
 SQLTokenSequence.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that holds a sequence of `SQLToken`.
public protocol SQLTokenSequence: Sequence {
  /// A type representing the sequence's elements.
  associatedtype Element: SQLToken = SQLToken

  /// A type representing a sequence of tokens.
  associatedtype Tokens: Sequence = Self where Self.Tokens.Element == Self.Element

  /// Provide a sequence of tokens.
  var tokens: Tokens { get }
}

extension SQLTokenSequence where Self.Tokens == Self {
  /// Provide itself as a sequence of tokens.
  public var tokens: Self {
    return self
  }
}

extension SQLTokenSequence where Self.Tokens == Array<Self.Element> {
  public typealias Iterator = Array<Element>.Iterator

  public func makeIterator() -> Array<Element>.Iterator {
    return tokens.makeIterator()
  }

  public var underestimatedCount: Int {
    return tokens.underestimatedCount
  }

  public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
    return try tokens.withContiguousStorageIfAvailable(body)
  }
}

internal extension Sequence where Element: SQLToken {
  var _description: String {
    var description = ""
    var previousToken: SQLToken? = nil
    for token in self {
      defer { previousToken = token }

      if token is SQLToken.Joiner {
        continue
      } else if previousToken is SQLToken.Joiner || previousToken == nil {
        description += token.description
      } else {
        description += " \(token.description)"
      }
    }
    return description
  }
}

extension SQLTokenSequence {
  public var description: String {
    return _description
  }
}

extension SQLTokenSequence {
  @inlinable
  internal func _opening<T>(_ job: (Self) throws -> T) rethrows -> T {
    return try job(self)
  }
}

/// A type erasure to be used in the case that `any Iterator<SQLToken>` is not available.
internal final class AnySQLTokenSequenceIterator: IteratorProtocol {
  typealias Element = SQLToken

  private class _Box {
    func next() -> SQLToken? { fatalError("Must be overridden.") }
  }
  private class _Base<T>: _Box where T: IteratorProtocol, T.Element: SQLToken {
    var _base: T
    init(_ base: T) { self._base = base }
    override func next() -> SQLToken? { _base.next() }
  }

  private let _box: _Box

  init<Iterator>(_ iterator: Iterator) where Iterator: IteratorProtocol, Iterator.Element: SQLToken {
    self._box = _Base(iterator)
  }

  init<S>(_ sequence: S) where S: Sequence, S.Iterator.Element: SQLToken {
    self._box = _Base(sequence.makeIterator())
  }

  func next() -> SQLToken? {
    return self._box.next()
  }
}
