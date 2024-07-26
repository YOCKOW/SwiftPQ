/* *************************************************************************************************
 SelectClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that is described as `select_clause` in "gram.y".
public struct SelectClause: Clause  {
  public class SelectQuery {
    fileprivate func makeIterator() -> AnyTokenSequenceIterator {
      fatalError("Must be overridden.")
    }

    fileprivate class _SelectStatement<T>: SelectQuery where T: SelectStatement {
      let statement: T

      override func makeIterator() -> AnyTokenSequenceIterator {
        return statement._anyIterator
      }

      init(_ statement: T) {
        self.statement = statement
      }
    }

    fileprivate final class _SimpleSelectStatement<T>: _SelectStatement<T>
      where T: SimpleSelectStatement
    {

    }

    fileprivate final class _ParenthesizedSelectStatement<T>: _SelectStatement<Parenthesized<T>>
      where T: SelectStatement
    {

    }
  }

  public let query: SelectQuery

  private init(query: SelectQuery) {
    self.query = query
  }

  public init<T>(_ statement: T) where T: SimpleSelectStatement {
    self.init(query: SelectQuery._SimpleSelectStatement<T>(statement))
  }

  public init<T>(_ parenthesized: Parenthesized<T>) where T: SelectStatement {
    self.init(query: SelectQuery._ParenthesizedSelectStatement<T>(parenthesized))
  }

  public struct Tokens: Sequence {
    public typealias Element = Token

    public struct Iterator: IteratorProtocol {
      public typealias Element = Token
      private let _iterator: AnyTokenSequenceIterator
      fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
      public func next() -> Token? { return _iterator.next() }
    }

    private let _query: SelectQuery

    public func makeIterator() -> Iterator {
      return Iterator(_query.makeIterator())
    }

    fileprivate init(_ query: SelectQuery) {
      self._query = query
    }
  }

  public var tokens: Tokens {
    return Tokens(query)
  }
}

extension SimpleSelectStatement {
  @inlinable
  public var asClause: SelectClause {
    return SelectClause(self)
  }
}

extension Parenthesized where EnclosedTokens: SelectStatement {
  @inlinable
  public var asClause: SelectClause {
    return SelectClause(self)
  }
}
