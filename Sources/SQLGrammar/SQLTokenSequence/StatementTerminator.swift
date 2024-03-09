/* *************************************************************************************************
 StatementTerminator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Statement terminator (;)
public final class StatementTerminator: SQLTokenSequence {
  public let tokens: [SQLToken] = [.joiner, .semicolon]
  public static let statementTerminator: StatementTerminator = .init()
}

/// Statement terminator (;)
public let statementTerminator: StatementTerminator = .statementTerminator

/// A type representing terminated statement.
public struct TerminatedStatement<T>: SQLTokenSequence where T: Statement {
  public typealias Element = SQLToken

  public let statement: T

  public init(_ statement: T) {
    self.statement = statement
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken

    private var _statementIterator: T.Iterator?
    private var _terminatorIterator: StatementTerminator.Iterator

    fileprivate init(_ base: TerminatedStatement) {
      self._statementIterator = base.statement.makeIterator()
      self._terminatorIterator = statementTerminator.makeIterator()
    }


    public mutating func next() -> Element? {
      guard let statementToken = _statementIterator?.next() else {
        _statementIterator = nil
        return _terminatorIterator.next()
      }
      return statementToken
    }
  }

  public func makeIterator() -> Iterator {
    return .init(self)
  }
}

extension Statement {
  /// Sequence of tokens where `;` is added to `self`.
  public var terminated: TerminatedStatement<Self> {
    return .init(self)
  }
}
