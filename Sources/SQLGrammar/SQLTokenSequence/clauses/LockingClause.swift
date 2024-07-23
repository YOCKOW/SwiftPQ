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

  private static let _forUpdateTokens: Array<SQLToken> = [.for, .update]
  private static let _forNoKeyUpdateTokens: Array<SQLToken> = [.for, .no, .key, .update]
  private static let _forShareTokens: Array<SQLToken> = [.for, .share]
  private static let _forKeyShareTokens: Array<SQLToken> = [.for, .key, .share]

  public var tokens: Array<SQLToken> {
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
public struct LockedRelationList: SQLTokenSequence,
                                  InitializableWithNonEmptyList,
                                  ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = TableName
  public typealias ArrayLiteralElement = TableName

  public let tableNames: QualifiedNameList<TableName>

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.of), tableNames)
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

  private static let _noWaitTokens: Array<SQLToken> = [.nowait]
  private static let _skipTokens: Array<SQLToken> = [.skip, .locked]

  public var tokens: Array<SQLToken> {
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
public struct LockingMode: SQLTokenSequence {
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
public struct LockingModeList: SQLTokenSequence,
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
  private enum _LockingMode: SQLTokenSequence {
    case readOnly
    case others(LockingModeList)

    private static let _readOnlyTokens: Array<SQLToken> = [.for, .read, .only]

    var tokens: AnySQLTokenSequence {
      switch self {
      case .readOnly:
        return AnySQLTokenSequence(UnknownSQLTokenSequence(_LockingMode._readOnlyTokens))
      case .others(let list):
        return AnySQLTokenSequence(list)
      }
    }

    func makeIterator() -> AnySQLTokenSequenceIterator {
      return tokens.makeIterator()
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
    public typealias Element = SQLToken

    public struct Iterator: IteratorProtocol {
      public typealias Element = SQLToken

      private let _iterator: AnySQLTokenSequenceIterator

      fileprivate init(_ iterator: AnySQLTokenSequenceIterator) {
        self._iterator = iterator
      }

      public func next() -> SQLToken? {
        return _iterator.next()
      }
    }

    private let _tokens: AnySQLTokenSequence

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

  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
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
