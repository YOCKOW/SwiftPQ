/* *************************************************************************************************
 LockingClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// Reference: https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE

/// Row-level lock mode that is described as `for_locking_strength` in "gram.y".
public enum LockingStrength: Segment {
  case update
  case noKeyUpdate
  case share
  case keyShare

  private static let _forUpdateTokens: Array<Token> = [.for, .update]
  private static let _forNoKeyUpdateTokens: Array<Token> = [.for, .no, .key, .update]
  private static let _forShareTokens: Array<Token> = [.for, .share]
  private static let _forKeyShareTokens: Array<Token> = [.for, .key, .share]

  public var tokens: Array<Token> {
    switch self {
    case .update:
      return LockingStrength._forUpdateTokens
    case .noKeyUpdate:
      return LockingStrength._forNoKeyUpdateTokens
    case .share:
      return LockingStrength._forShareTokens
    case .keyShare:
      return LockingStrength._forKeyShareTokens
    }
  }
}

/// A list of locked tables. Described as `locked_rels_list` in "gram.y".
public struct LockedRelationList: TokenSequenceGenerator,
                                  InitializableWithNonEmptyList,
                                  ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = TableName
  public typealias ArrayLiteralElement = TableName

  public let tableNames: QualifiedNameList<TableName>

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken.of, tableNames)
  }

  public init(_ tableNames: QualifiedNameList<TableName>) {
    self.tableNames = tableNames
  }

  public init(_ list: NonEmptyList<TableName>) {
    self.tableNames = QualifiedNameList<TableName>(list)
  }
}

/// An waiting option that is described as `opt_nowait_or_skip` in "gram.y".
public enum LockingWaitOption: Segment {
  case noWait
  case skip

  private static let _noWaitTokens: Array<Token> = [.nowait]
  private static let _skipTokens: Array<Token> = [.skip, .locked]

  public var tokens: Array<Token> {
    switch self {
    case .noWait:
      return LockingWaitOption._noWaitTokens
    case .skip:
      return LockingWaitOption._skipTokens
    }
  }
}

/// A combination of *strength*, *relation list*(optional), and *wait option*(optional).
/// Described as `for_locking_item` in "gram.y".
public struct LockingMode: TokenSequenceGenerator {
  public let strength: LockingStrength

  public let tableNames: LockedRelationList?

  public let waitOption: LockingWaitOption?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(strength, tableNames, waitOption)
  }

  public init(
    for strength: LockingStrength,
    of tableNames: LockedRelationList? = nil,
    waitOption: LockingWaitOption? = nil
  ) {
    self.strength = strength
    self.tableNames = tableNames
    self.waitOption = waitOption
  }

  public static func forUpdate(
    of tableNames: LockedRelationList? = nil,
    waitOption: LockingWaitOption? = nil
  ) -> LockingMode {
    return LockingMode(for: .update, of: tableNames, waitOption: waitOption)
  }

  public static func forNoKeyUpdate(
    of tableNames: LockedRelationList? = nil,
    waitOption: LockingWaitOption? = nil
  ) -> LockingMode {
    return LockingMode(for: .noKeyUpdate, of: tableNames, waitOption: waitOption)
  }

  public static func forShare(
    of tableNames: LockedRelationList? = nil,
    waitOption: LockingWaitOption? = nil
  ) -> LockingMode {
    return LockingMode(for: .share, of: tableNames, waitOption: waitOption)
  }

  public static func forKeyShare(
    of tableNames: LockedRelationList? = nil,
    waitOption: LockingWaitOption? = nil
  ) -> LockingMode {
    return LockingMode(for: .keyShare, of: tableNames, waitOption: waitOption)
  }
}

/// A list of locking modes. Described as `for_locking_items` in "gram.y".
public struct LockingModeList: TokenSequenceGenerator,
                               InitializableWithNonEmptyList,
                               ExpressibleByArrayLiteral {
  public let modes: NonEmptyList<LockingMode>

  public var tokens: JoinedSQLTokenSequence {
    return modes.joined()
  }

  public init(_ modes: NonEmptyList<LockingMode>) {
    self.modes = modes
  }
}



/// `FOR {UPDATE | NO KEY UPDATE | SHARE | KEY SHARE} ...` clause
/// that is described as `for_locking_clause` in "gram.y".
public struct LockingClause: Clause {
  private enum _LockingMode: TokenSequenceGenerator {
    case readOnly
    case others(LockingModeList)

    private static let _readOnlyTokens: Array<Token> = [.for, .read, .only]

    var tokens: AnyTokenSequenceGenerator.Tokens {
      switch self {
      case .readOnly:
        return AnyTokenSequenceGenerator(UnknownSQLTokenSequence(_LockingMode._readOnlyTokens)).tokens
      case .others(let list):
        return AnyTokenSequenceGenerator(list).tokens
      }
    }
  }

  private let _mode: _LockingMode

  public var isReadOnlyMode: Bool {
    guard case .readOnly = _mode else {
      return false
    }
    return true
  }

  public var modeList: LockingModeList? {
    guard case .others(let list) = _mode else {
      return nil
    }
    return list
  }

  public struct Tokens: Sequence {
    public typealias Element = Token

    public struct Iterator: IteratorProtocol {
      public typealias Element = Token

      private let _iterator: AnyTokenSequenceIterator

      fileprivate init(_ iterator: AnyTokenSequenceIterator) {
        self._iterator = iterator
      }

      public func next() -> Token? {
        return _iterator.next()
      }
    }

    private let _tokens: AnyTokenSequenceGenerator.Tokens

    fileprivate init(_ clause: LockingClause) {
      self._tokens = clause._mode.tokens
    }

    public func makeIterator() -> Iterator {
      return Iterator(_tokens.makeIterator())
    }
  }

  public var tokens: Tokens {
    return Tokens(self)
  }

  private init(mode: _LockingMode) {
    self._mode = mode
  }

  public init(_ list: LockingModeList) {
    self.init(mode: .others(list))
  }

  public init(_ mode: LockingMode) {
    self.init(mode: .others(LockingModeList(NonEmptyList<LockingMode>(item: mode))))
  }

  public static let forReadOnly: LockingClause = .init(mode: .readOnly)
}
