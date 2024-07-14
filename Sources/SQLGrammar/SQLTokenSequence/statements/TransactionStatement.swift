/* *************************************************************************************************
 TransactionStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An optional keyword used in transaction statements. This is described as `opt_transaction` in
/// "gram.y".
public enum TransactionKeyword: CustomTokenConvertible {
  case work
  case transaction

  public var token: SQLToken {
    switch self {
    case .work:
      return .work
    case .transaction:
      return .transaction
    }
  }
}

/// Isolation level for transaction mode that is described as `iso_level` in "gram.y".
public enum IsolationLevel: SQLTokenSequence {
  case readUncommitted
  case readCommitted
  case repeatableRead
  case serializable

  public final class Tokens: SQLTokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }

    public static let readUncommitted: Tokens = .init([.read, .uncommitted])
    public static let readCommitted: Tokens = .init([.read, .committed])
    public static let repeatableRead: Tokens = .init([.repeatable, .read])
    public static let serializable: Tokens = .init([.serializable])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .readUncommitted:
      return .readUncommitted
    case .readCommitted:
      return .readCommitted
    case .repeatableRead:
      return .repeatableRead
    case .serializable:
      return .serializable
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}

/// A mode for transaction that is described as `transaction_mode_item` in "gram.y".
public enum TransactionMode: SQLTokenSequence {
  case isolationLevel(IsolationLevel)
  case readOnly
  case readWrite
  case deferrable
  case notDeferrable

  public final class Tokens: SQLTokenSequence {
    public let tokens: JoinedSQLTokenSequence
    private init(_ tokens: JoinedSQLTokenSequence) { self.tokens = tokens }

    public static func isolationLevel(_ level: IsolationLevel) -> Tokens {
      enum __IsolationLevel {
        static let tokens: UnknownSQLTokenSequence<Array<SQLToken>> = .init([.isolation, .level])
      }
      return .init(JoinedSQLTokenSequence(__IsolationLevel.tokens, level))
    }

    public static let readOnly: Tokens = .init(
      JoinedSQLTokenSequence(UnknownSQLTokenSequence<Array<SQLToken>>([.read, .only]))
    )

    public static let readWrite: Tokens = .init(
      JoinedSQLTokenSequence(UnknownSQLTokenSequence<Array<SQLToken>>([.read, .write]))
    )

    public static let deferrable: Tokens = .init(JoinedSQLTokenSequence(SingleToken(.deferrable)))

    public static let notDeferrable: Tokens = .init(
      JoinedSQLTokenSequence(UnknownSQLTokenSequence<Array<SQLToken>>([.not, .deferrable]))
    )
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .isolationLevel(let isolationLevel):
      return .isolationLevel(isolationLevel)
    case .readOnly:
      return .readOnly
    case .readWrite:
      return .readWrite
    case .deferrable:
      return .deferrable
    case .notDeferrable:
      return .notDeferrable
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}

/// A list of `TransactionMode`. This is described as `transaction_mode_list` in "gram.y".
public struct TransactionModeList: SQLTokenSequence,
                                   InitializableWithNonEmptyList,
                                   ExpressibleByArrayLiteral {
  public var modes: NonEmptyList<TransactionMode>

  /// A boolean value that indicates whether or not commas are omitted in this clause.
  public var omitCommas: Bool = false

  public var tokens: JoinedSQLTokenSequence {
    if omitCommas {
      return modes.joined()
    } else {
      return modes.joinedByCommas()
    }
  }

  public init(_ modes: NonEmptyList<TransactionMode>) {
    self.modes = modes
  }
}

/// Specifier of transaction chain that is described as `opt_transaction_chain` in "gram.y".
public enum TransactionChain: SQLTokenSequence {
  case chain
  case noChain

  public final class Tokens: SQLTokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }
    public static let chain: Tokens = .init([.and, .chain])
    public static let noChain: Tokens = .init([.and, .no, .chain])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .chain:
      return .chain
    case .noChain:
      return .noChain
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}

/// A legacy statement to declare transaction that is described as `TransactionStmtLegacy` in
/// "gram.y".
public enum LegacyTransactionStatement: TopLevelStatement {
  case begin(TransactionKeyword? = nil, modes: TransactionModeList?)
  public static let begin: LegacyTransactionStatement = .begin(modes: nil)

  case end(TransactionKeyword? = nil, and: TransactionChain?)
  public static let end: LegacyTransactionStatement = .end(and: nil)

  public var tokens: JoinedSQLTokenSequence {
    switch self {
    case .begin(let keyword, let modes):
      return .compacting(SingleToken(.begin), keyword?.asSequence, modes)
    case .end(let keyword, let chain):
      return .compacting(SingleToken(.end), keyword?.asSequence, chain)
    }
  }
}
