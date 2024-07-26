/* *************************************************************************************************
 TokenSequenceGenerator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that holds a sequence of `SQLToken`.
public protocol TokenSequenceGenerator {
  /// A type representing a sequence of tokens.
  associatedtype Tokens: Sequence where Self.Tokens.Element: SQLToken

  /// Provide a sequence of tokens.
  var tokens: Tokens { get }
}

/// A type that is a sequence of `SQLToken`.
/// It is supposed to use `Token` as a concrete sequence instead of itself.
public protocol TokenSequence: Sequence, TokenSequenceGenerator where Self.Element == Tokens.Element {}
extension TokenSequence where Self.Iterator == Tokens.Iterator {
  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return self.tokens.makeIterator()
  }
}
extension TokenSequence where Self.Tokens == Self {
  /// Provide itself as a sequence of tokens.
  public var tokens: Self {
    return self
  }

  public func makeIterator() -> Self.Iterator {
    // Prevent recursive calls.
    fatalError("Required to implement its own `makeIterator()`.")
  }
}

/// A type representing a top-level statement which is expressed as `toplevel_stmt` in "gram.y".
public protocol TopLevelStatement: TokenSequenceGenerator {}

/// A type representing a statement which is expressed as `stmt` in "gram.y".
public protocol Statement: TopLevelStatement {}

/// A type that reprents `PreparableStmt` in "gram.y".
public protocol PreparableStatement: Statement {}

/// A type representing an expression.
public protocol Expression: TokenSequenceGenerator {}

/// A type representing an expression that can contain itself in its definition.
///
/// For example, one of `a_expr` is defined as `a_expr '+' a_expr`.
public protocol RecursiveExpression: Expression {}

/// A type representing an expression that is described as `a_expr` in "gram.y".
public protocol GeneralExpression: RecursiveExpression {}

/// A type representing an expression that is described as `b_expr` in "gram.y".
public protocol RestrictedExpression: RecursiveExpression {}

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
public protocol Segment: TokenSequenceGenerator {}

/// A type representing a kind of a clause.
public protocol Clause: Segment {}

internal extension Sequence where Element: SQLToken {
  var _description: String {
    var description = ""
    var previousToken: SQLToken? = nil
    for token in self {
      defer { previousToken = token }

      if token is SQLToken.Joiner {
        continue
      } else if (
        previousToken == nil ||
        previousToken is SQLToken.Joiner ||
        previousToken is SQLToken.Newline || token is SQLToken.Newline
      ) {
        description += token.description
      } else {
        description += " \(token.description)"
      }
    }
    return description
  }
}

extension TokenSequenceGenerator {
  public var description: String {
    return self.tokens._description
  }
}

/// A type erasure to be used in the case that `any Iterator<SQLToken>` is not available.
internal final class AnyTokenSequenceIterator: IteratorProtocol {
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

/// A type erasure to be used in the case that `any TokenSequenceGenerator` is not available.
internal class AnyTokenSequenceGenerator: TokenSequenceGenerator {
  class Tokens: Sequence {
    typealias Element = SQLToken
    typealias Iterator = AnyTokenSequenceIterator
    func makeIterator() -> AnyTokenSequenceIterator { fatalError("Must be overridden.") }

    fileprivate final class _BaseGenerator<T>: Tokens where T: TokenSequenceGenerator {
      private let _generator: T
      init(_ generator: T) { self._generator = generator }
      override func makeIterator() -> AnyTokenSequenceIterator {
        return .init(_generator.tokens)
      }
    }
  }

  let tokens: Tokens

  init<T>(_ base: T) where T: TokenSequenceGenerator {
    self.tokens = Tokens._BaseGenerator<T>(base)
  }
}

/// A type erasure to be used in the case that `any TokenSequence` is not available.
internal final class AnyTokenSequence: AnyTokenSequenceGenerator, TokenSequence {}

extension TokenSequenceGenerator {
  internal var _asAny: AnyTokenSequenceGenerator {
    return AnyTokenSequenceGenerator(self)
  }

  internal var _anyIterator: AnyTokenSequenceIterator {
    return _asAny.tokens.makeIterator()
  }
}

extension TokenSequence {
  internal var _asAny: AnyTokenSequence {
    return AnyTokenSequence(self)
  }
}
