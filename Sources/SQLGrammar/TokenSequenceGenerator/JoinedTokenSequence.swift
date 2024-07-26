/* *************************************************************************************************
 JoinedTokenSequence.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Joined `Token` sequence with `separator`.
public struct JoinedTokenSequence: TokenSequence {
  fileprivate let _sequences: Array<any TokenSequenceGenerator>

  public let separator: Array<Token>?

  /// "Designated" initializer. Other initializers should call this in principle to prevent
  /// infinite recursion due to wrong implementation.
  private init(_sequences: Array<any TokenSequenceGenerator>, separator: Array<Token>?) {
    self._sequences = _sequences
    self.separator = separator
  }

  /// Initializes with the given list of `sequences` and `separator`.
  public init<Separator>(
    _ sequences: Array<any TokenSequenceGenerator>,
    separator: Separator? = Optional<Array<Token>>.none
  ) where Separator: Sequence, Separator.Element: Token {
    self.init(_sequences: sequences, separator: separator.map({ Array<Token>($0) }))
  }

  /// Initializes with the given list of `sequences` and `separator`.
  public init<Separator>(
    _ sequences: Array<any TokenSequenceGenerator>,
    separator: Separator
  ) where Separator: TokenSequenceGenerator {
    self.init(_sequences: sequences, separator: Array<Token>(separator.tokens))
  }

  /// Initializes with the given list of `sequences` and `separator`.
  public init<S, Separator>(
    _ sequences: S,
    separator: Separator? = Optional<Array<Token>>.none
  ) where S: Sequence, S.Element == any TokenSequenceGenerator, Separator: Sequence, Separator.Element: Token {
    self.init(
      _sequences: Array<any TokenSequenceGenerator>(sequences),
      separator: separator.map({ Array<Token>($0) })
    )
  }

  /// Initializes with the given list of `sequences` and `separator`.
  public init<S, Separator>(
    _ sequences: S,
    separator: Separator
  ) where S: Sequence, S.Element == any TokenSequenceGenerator, Separator: TokenSequenceGenerator {
    self.init(
      _sequences: Array<any TokenSequenceGenerator>(sequences),
      separator: Array<Token>(separator.tokens)
    )
  }

  /// Initializes with the given list of `sequences` and `separator`.
  public init<S, Separator>(
    _ sequences: S,
    separator: Separator? = Optional<Array<Token>>.none
  ) where S: Sequence, S.Element: TokenSequenceGenerator, Separator: Sequence, Separator.Element: Token {
    self.init(
      _sequences: sequences.map({ $0 as any TokenSequenceGenerator }),
      separator: separator.map({ Array<Token>($0) })
    )
  }

  /// Initializes with the given list of `sequences` and `separator`.
  public init<S, Separator>(
    _ sequences: S,
    separator: Separator
  ) where S: Sequence, S.Element: TokenSequenceGenerator, Separator: TokenSequenceGenerator {
    self.init(
      _sequences: sequences.map({ $0 as any TokenSequenceGenerator }),
      separator: Array<Token>(separator.tokens)
    )
  }

  /// Initializes with the given list of `sequence` and `separator`.
  public init<each S, Separator>(
    _ sequence: repeat each S,
    separator: Separator?  = Optional<Array<Token>>.none
  ) where repeat each S: TokenSequenceGenerator, Separator: Sequence, Separator.Element: Token {
    var sequences: [any TokenSequenceGenerator] = []
    repeat (sequences.append(each sequence))
    self.init(_sequences: sequences, separator: separator.map({ Array<Token>($0) }))
  }

  /// Initializes with the given list of `sequence` and `separator`.
  public init<each S, Separator>(
    _ sequence: repeat each S,
    separator: Separator
  ) where repeat each S: TokenSequenceGenerator, Separator: TokenSequenceGenerator {
    self.init(repeat each sequence, separator: separator.tokens)
  }

  /// Returns a joined sequence that is created with the given list of `sequences` omitting `nil`
  /// and `separator`.
  public static func compacting<Separator>(
    _ sequences: Array<(any TokenSequenceGenerator)?>,
    separator: Separator? = Optional<Array<Token>>.none
  ) -> JoinedTokenSequence where Separator: Sequence, Separator.Element: Token {
    return .init(
      _sequences: sequences.compactMap({ $0 }),
      separator: separator.map({ Array<Token>($0) })
    )
  }

  /// Returns a joined sequence that is created with the given list of `sequences` omitting `nil`
  /// and `separator`.
  public static func compacting<Separator>(
    _ sequences: Array<(any TokenSequenceGenerator)?>,
    separator: Separator
  ) -> JoinedTokenSequence where Separator: TokenSequenceGenerator {
    return .init(
      _sequences: sequences.compactMap({ $0 }),
      separator: Array<Token>(separator.tokens)
    )
  }

  /// Returns a joined sequence that is created with the given list of `sequences` omitting `nil`
  /// and `separator`.
  public static func compacting<S, Separator>(
    _ sequences: S,
    separator: Separator? = Optional<Array<Token>>.none
  ) -> JoinedTokenSequence where S: Sequence, S.Element == (any TokenSequenceGenerator)?,
                                    Separator: Sequence, Separator.Element: Token
  {
    return .init(
      _sequences: sequences.compactMap({ $0 }),
      separator: separator.map({ Array<Token>($0) })
    )
  }

  /// Returns a joined sequence that is created with the given list of `sequences` omitting `nil`
  /// and `separator`.
  public static func compacting<S, Separator>(
    _ sequences: S,
    separator: Separator
  ) -> JoinedTokenSequence where S: Sequence, S.Element == (any TokenSequenceGenerator)?,
                                    Separator: TokenSequenceGenerator
  {
    return .init(
      _sequences: sequences.compactMap({ $0 }),
      separator: Array<Token>(separator.tokens)
    )
  }

  /// Returns a joined sequence that is created with the given list of `sequence` omitting `nil`
  /// and `separator`.
  public static func compacting<each S, Separator>(
    _ sequence: repeat Optional<each S>,
    separator: Separator?  = Optional<Array<Token>>.none
  ) -> JoinedTokenSequence where repeat each S: TokenSequenceGenerator,
                                    Separator: Sequence, Separator.Element: Token
  {
    var sequences: [any TokenSequenceGenerator] = []
    func __appendIfNotNil(_ sequence: (any TokenSequenceGenerator)?) {
      if let sequence {
        sequences.append(sequence)
      }
    }
    repeat (__appendIfNotNil(each sequence))
    return .init(sequences, separator: separator)
  }

  @inlinable
  public static func compacting<each S, Separator>(
    _ sequence: repeat Optional<each S>,
    separator: Separator
  ) -> JoinedTokenSequence where repeat each S: TokenSequenceGenerator,
                                    Separator: TokenSequenceGenerator
  {
    return .compacting(repeat each sequence, separator: separator.tokens)
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = Token

    private let _joinedSequence: JoinedTokenSequence
    private var _currentIndex: Int
    private var _currentIterator: Optional<AnyTokenSequenceIterator>
    private var _currentSequenceIsSeparator: Bool

    fileprivate init(_ joinedSequence: JoinedTokenSequence) {
      self._joinedSequence = joinedSequence
      self._currentIndex = joinedSequence._sequences.startIndex
      self._currentIterator = joinedSequence._sequences.first.map { $0._anyIterator }
      self._currentSequenceIsSeparator = false
    }

    private var _sequences: [any TokenSequenceGenerator] { _joinedSequence._sequences }

    private var _separator: Array<Token>? { _joinedSequence.separator }

    public mutating func next() -> Token? {
      func __next() -> Token? {
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
          _currentIterator = AnyTokenSequenceIterator(separator)
          _currentSequenceIsSeparator = true
        case (false, nil), (true, _?):
          _currentIndex += 1
          if _currentIndex == _sequences.endIndex {
            _currentIterator = nil
            return nil
          }
          _currentIterator = _sequences[_currentIndex]._anyIterator
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

extension Collection where Element: Token {
  /// Returns joined tokens with `separator`.
  public func joined<Separator>(
    separator: Separator? = Optional<Array<Token>>.none
  ) -> JoinedTokenSequence where Separator: Sequence, Separator.Element: Token {
    return JoinedTokenSequence(self.map({ SingleToken($0) }), separator: separator)
  }

  /// Returns joined tokens with `separator`.
  @inlinable
  public func joined<Separator>(
    separator: Separator
  ) -> JoinedTokenSequence where Separator: TokenSequenceGenerator {
    return self.joined(separator: separator.tokens)
  }

  @inlinable
  public func joinedByCommas() -> JoinedTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}

extension Collection where Element: LosslessTokenConvertible {
  /// Returns joined tokens with `separator`.
  @inlinable
  public func joined<Separator>(
    separator: Separator? = Optional<Array<Token>>.none
  ) -> JoinedTokenSequence where Separator: Sequence, Separator.Element: Token {
    return JoinedTokenSequence(self.map({ $0.asSequence }), separator: separator)
  }

  /// Returns joined tokens with `separator`.
  @inlinable
  public func joined<Separator>(
    separator: Separator
  ) -> JoinedTokenSequence where Separator: TokenSequenceGenerator {
    return self.joined(separator: separator.tokens)
  }

  @inlinable
  public func joinedByCommas() -> JoinedTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}

extension Collection where Element == any TokenSequenceGenerator {
  /// Returns joined tokens with `separator`.
  @inlinable
  public func joined<S>(separator: S? = Optional<Array<Token>>.none) -> JoinedTokenSequence where S: Sequence, S.Element: Token {
    return JoinedTokenSequence(self, separator: separator)
  }

  /// Returns joined tokens with `separator`.
  @inlinable
  public func joined<S>(separator: S) -> JoinedTokenSequence where S: TokenSequenceGenerator {
    return self.joined(separator: separator.tokens)
  }

  @inlinable
  public func joinedByCommas() -> JoinedTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}

extension Collection where Element: TokenSequenceGenerator {
  /// Returns joined tokens with `separator`.
  public func joined<S>(separator: S? = Optional<Array<Token>>.none) -> JoinedTokenSequence where S: Sequence, S.Element: Token {
    return JoinedTokenSequence(self, separator: separator)
  }

  /// Returns joined tokens with `separator`.
  @inlinable
  public func joined<S>(separator: S) -> JoinedTokenSequence where S: TokenSequenceGenerator {
    return self.joined(separator: separator.tokens)
  }

  @inlinable
  public func joinedByCommas() -> JoinedTokenSequence {
    return self.joined(separator: commaSeparator)
  }
}
