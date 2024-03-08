/* *************************************************************************************************
 JoinedSQLTokenSequence.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Joined SQLToken sequence with `separator`.
public struct JoinedSQLTokenSequence: SQLTokenSequence {
  fileprivate let _sequences: [any SQLTokenSequence]

  public let separator: Array<SQLToken>?

  public init<S, Separator>(
    _ sequences: S,
    separator: Separator? = nil
  ) where S: Sequence, S.Element == any SQLTokenSequence, Separator: Sequence, Separator.Element: SQLToken {
    self._sequences = Array<any SQLTokenSequence>(sequences)
    self.separator = separator.map({ $0.map({ $0 as SQLToken }) })
  }

  public init<S, Separator>(
    _ sequences: S,
    separator: Separator? = nil
  ) where S: Sequence, S.Element: SQLTokenSequence, Separator: Sequence, Separator.Element: SQLToken {
    self.init(sequences.map({ $0 as any SQLTokenSequence }), separator: separator)

  }

  public init<each S, Separator>(_ sequence: repeat each S, separator: Separator? = nil) where repeat each S: SQLTokenSequence, Separator: Sequence, Separator.Element: SQLToken {
    var sequences: [any SQLTokenSequence] = []
    repeat (sequences.append(each sequence))
    self.init(sequences, separator: separator)
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken

    private let _joinedSequence: JoinedSQLTokenSequence
    private var _currentIndex: Int
    private var _currentIterator: Optional<AnySQLTokenSequenceIterator>
    private var _currentSequenceIsSeparator: Bool

    fileprivate init(_ joinedSequence: JoinedSQLTokenSequence) {
      self._joinedSequence = joinedSequence
      self._currentIndex = joinedSequence._sequences.startIndex
      self._currentIterator = joinedSequence._sequences.first.map { AnySQLTokenSequenceIterator($0) }
      self._currentSequenceIsSeparator = false
    }

    private var _sequences: [any SQLTokenSequence] { _joinedSequence._sequences }

    private var _separator: Array<SQLToken>? { _joinedSequence.separator }

    public mutating func next() -> SQLToken? {
      func __next() -> SQLToken? {
        guard let currentIterator = _currentIterator else { return nil }
        if let nextToken = currentIterator.next() {
          return nextToken
        }

        switch (_currentSequenceIsSeparator, _separator) {
        case (false, let separator?):
          guard _currentIndex < _sequences.endIndex - 1 else {
            _currentIterator = nil
            return nil
          }
          _currentIterator = AnySQLTokenSequenceIterator(separator)
          _currentSequenceIsSeparator = true
        case (false, nil), (true, _?):
          _currentIndex += 1
          if _currentIndex == _sequences.endIndex {
            _currentIterator = nil
            return nil
          }
          _currentIterator = _sequences[_currentIndex]._opening({ AnySQLTokenSequenceIterator($0) })
          _currentSequenceIsSeparator = false
        case (true, nil):
          fatalError("What happened?!")
        }
        return __next()
      }
      return __next()
    }
  }

  public func makeIterator() -> Iterator {
    return .init(self)
  }
}

extension Collection where Element: SQLToken {
  /// Returns joined tokens with `separator`.
  public func joined<Separator>(
    separator: Separator? = Optional<Array<SQLToken>>.none
  ) -> JoinedSQLTokenSequence where Separator: Sequence, Separator.Element == SQLToken {
    return JoinedSQLTokenSequence(self.map({ SingleToken($0) }), separator: separator)
  }

  @inlinable
  public func joinedByCommas() -> JoinedSQLTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}

extension Array where Element == any SQLTokenSequence {
  /// Returns joined tokens with `separator`.
  public func joined<S>(separator: S? = Optional<Array<SQLToken>>.none) -> JoinedSQLTokenSequence where S: Sequence, S.Element: SQLToken {
    return JoinedSQLTokenSequence(self, separator: separator)
  }

  @inlinable
  public func joinedByCommas() -> JoinedSQLTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}

extension Collection where Element: SQLTokenSequence {
  /// Returns joined tokens with `separator`.
  public func joined<S>(separator: S? = Optional<Array<SQLToken>>.none) -> JoinedSQLTokenSequence where S: Sequence, S.Element == SQLToken {
    return JoinedSQLTokenSequence(self, separator: separator)
  }

  @inlinable
  public func joinedByCommas() -> JoinedSQLTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}
