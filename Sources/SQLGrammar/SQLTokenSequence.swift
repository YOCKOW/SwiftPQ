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
  associatedtype Tokens: Sequence where Self.Tokens.Element == Self.Element

  /// A type that provides the sequence's iteration interface.
  associatedtype Iterator: IteratorProtocol = Self.Tokens.Iterator where Self.Iterator.Element == Self.Element

  /// Provide a sequence of tokens.
  var tokens: Tokens { get }
}

/// A type representing a statement which is expressed as `stmt` in "gram.y".
public protocol Statement: SQLTokenSequence {}

/// A type representing an expression.
public protocol Expression: SQLTokenSequence {}

/// A type representing an expression that is described as `a_expr` in "gram.y".
public protocol GeneralExpression: Expression {}

/// A type representing an expression that is described as `b_expr` in "gram.y".
public protocol RestrictedExpression: Expression {}

/// A type representing an expression that is described as `c_expr` in "gram.y".
///
/// - Note: `a_expr` (`GeneralExpression` in this module) is defined as `c_expr | ...`,
/// and `b_expr` (`RestrictedExpression` in  this module) is also defined as `c_expr | ...`,
/// that means `c_expr` can be `a_expr` or `b_expr` per se.
public protocol ProductionExpression: Expression, GeneralExpression, RestrictedExpression {}

/// A type representing "value expression".
///
/// Reference: [PostgreSQL Documentation §4.2. Value Expressions](https://www.postgresql.org/docs/current/sql-expressions.html)
public protocol ValueExpression: Expression {}

/// A type representing some kind of token sequence that is, for example, a part of a statement.
public protocol Segment: SQLTokenSequence {}

/// A type representing a kind of a clause.
public protocol Clause: Segment {}

extension SQLTokenSequence where Self.Tokens == Self {
  /// Provide itself as a sequence of tokens.
  public var tokens: Self {
    return self
  }
}

extension SQLTokenSequence where Self.Tokens == Array<Self.Element> {
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

// Note: `extension SQLTokenSequence where Self.Tokens: SQLTokenSequence`
//       may induce infinite recursion if implementation is not appropriate.

extension SQLTokenSequence where Self.Tokens == JoinedSQLTokenSequence {
  public func makeIterator() -> JoinedSQLTokenSequence.Iterator {
    return tokens.makeIterator()
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

/// A type erasure to be sed in the case that `any SQLTokenSequence` is not available.
internal final class AnySQLTokenSequence: SQLTokenSequence {
  typealias Element = SQLToken
  typealias Tokens = AnySQLTokenSequence
  typealias Iterator = AnySQLTokenSequenceIterator

  private class _Box {
    func makeIterator() -> AnySQLTokenSequenceIterator { fatalError("Must be overriden.") }
  }
  private class _Base<T>: _Box where T: SQLTokenSequence {
    let _base: T
    init(_ base: T) { self._base = base }
    override func makeIterator() -> AnySQLTokenSequenceIterator {
      return .init(_base)
    }
  }

  private let _box: _Box

  init<T>(_ base: T) where T: SQLTokenSequence {
    self._box = _Base<T>(base)
  }

  func makeIterator() -> AnySQLTokenSequenceIterator {
    return _box.makeIterator()
  }
}
