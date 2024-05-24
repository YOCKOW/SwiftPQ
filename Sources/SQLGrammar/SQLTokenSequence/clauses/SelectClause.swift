/* *************************************************************************************************
 SelectClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that is described as `select_clause` in "gram.y".
public struct SelectClause: Clause  {
  public class SelectQuery {
    fileprivate func makeIterator() -> AnySQLTokenSequenceIterator {
      fatalError("Must be overridden.")
    }

    fileprivate class _SelectStatement<T>: SelectQuery where T: SelectStatement {
      let statement: T

      override func makeIterator() -> AnySQLTokenSequenceIterator {
        return AnySQLTokenSequenceIterator(statement)
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

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken

    private let _iterator: AnySQLTokenSequenceIterator

    fileprivate init(_ iterator: AnySQLTokenSequenceIterator) {
      self._iterator = iterator
    }

    public mutating func next() -> SQLToken? {
      return _iterator.next()
    }
  }

  public struct Tokens: Sequence {
    public typealias Element = SQLToken

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

  public func makeIterator() -> Iterator {
    return tokens.makeIterator()
  }
}

