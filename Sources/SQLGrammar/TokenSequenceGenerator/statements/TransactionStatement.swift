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

  public var token: Token {
    switch self {
    case .work:
      return .work
    case .transaction:
      return .transaction
    }
  }
}

/// Isolation level for transaction mode that is described as `iso_level` in "gram.y".
public enum IsolationLevel: TokenSequenceGenerator {
  case readUncommitted
  case readCommitted
  case repeatableRead
  case serializable

  public final class Tokens: TokenSequence {
    public let tokens: Array<Token>
    private init(_ tokens: Array<Token>) { self.tokens = tokens }

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
}

/// A mode for transaction that is described as `transaction_mode_item` in "gram.y".
public enum TransactionMode: TokenSequenceGenerator {
  case isolationLevel(IsolationLevel)
  case readOnly
  case readWrite
  case deferrable
  case notDeferrable

  public final class Tokens: TokenSequence {
    public let tokens: JoinedTokenSequence
    private init(_ tokens: JoinedTokenSequence) { self.tokens = tokens }

    public static func isolationLevel(_ level: IsolationLevel) -> Tokens {
      enum __IsolationLevel {
        static let tokens: UnknownSQLTokenSequence<Array<Token>> = .init([.isolation, .level])
      }
      return .init(JoinedTokenSequence(__IsolationLevel.tokens, level))
    }

    public static let readOnly: Tokens = .init(
      JoinedTokenSequence(UnknownSQLTokenSequence<Array<Token>>([.read, .only]))
    )

    public static let readWrite: Tokens = .init(
      JoinedTokenSequence(UnknownSQLTokenSequence<Array<Token>>([.read, .write]))
    )

    public static let deferrable: Tokens = .init(JoinedTokenSequence(SingleToken.deferrable))

    public static let notDeferrable: Tokens = .init(
      JoinedTokenSequence(UnknownSQLTokenSequence<Array<Token>>([.not, .deferrable]))
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
}

/// A list of `TransactionMode`. This is described as `transaction_mode_list` in "gram.y".
public struct TransactionModeList: TokenSequenceGenerator,
                                   InitializableWithNonEmptyList,
                                   ExpressibleByArrayLiteral {
  public var modes: NonEmptyList<TransactionMode>

  /// A boolean value that indicates whether or not commas are omitted in this clause.
  public var omitCommas: Bool = false

  public var tokens: JoinedTokenSequence {
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
public enum TransactionChain: TokenSequenceGenerator {
  case chain
  case noChain

  public final class Tokens: TokenSequence {
    public let tokens: Array<Token>
    private init(_ tokens: Array<Token>) { self.tokens = tokens }
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
}

/// A legacy statement to declare transaction that is described as `TransactionStmtLegacy` in
/// "gram.y".
public enum LegacyTransactionStatement: TopLevelStatement {
  case begin(TransactionKeyword? = nil, modes: TransactionModeList?)
  public static let begin: LegacyTransactionStatement = .begin(modes: nil)

  case end(TransactionKeyword? = nil, and: TransactionChain?)
  public static let end: LegacyTransactionStatement = .end(and: nil)

  public var tokens: JoinedTokenSequence {
    switch self {
    case .begin(let keyword, let modes):
      return .compacting(SingleToken.begin, keyword?.asSequence, modes)
    case .end(let keyword, let chain):
      return .compacting(SingleToken.end, keyword?.asSequence, chain)
    }
  }
}

/// A statement representing a type of transaction command that is described as `TransactionStmt` in
///  "gram.y".
public struct TransactionStatement: Statement {
  public enum Command {
    /// Representation of `ABORT_P opt_transaction opt_transaction_chain`
    case abort(TransactionKeyword?, TransactionChain?)

    /// Representation of `START TRANSACTION transaction_mode_list_or_empty`
    case startTransaction(TransactionModeList?)

    /// Representation of `COMMIT opt_transaction opt_transaction_chain`
    case commit(TransactionKeyword?, TransactionChain?)

    /// Representation of `ROLLBACK opt_transaction opt_transaction_chain`
    case rollback(TransactionKeyword?, TransactionChain?)

    //// Representation of `SAVEPOINT ColId`
    case savePoint(ColumnIdentifier)

    /// Representation of `RELEASE SAVEPOINT ColId` or `RELEASE ColId`
    case release(omitSavePointKeyword: Bool, savePointName: ColumnIdentifier)

    /// Representation of `ROLLBACK opt_transaction TO SAVEPOINT ColId` or
    /// `ROLLBACK opt_transaction TO ColId`
    case rollbackToSavePoint(
      TransactionKeyword?,
      omitSavePointKeyword: Bool,
      savePointName: ColumnIdentifier
    )

    /// Representation of `PREPARE TRANSACTION Sconst`
    case prepareTransaction(StringConstantExpression)

    /// Representation of `COMMIT PREPARED Sconst`
    case commitPrepared(StringConstantExpression)

    /// Representation of `ROLLBACK PREPARED Sconst`
    case rollbackPrepared(StringConstantExpression)
  }

  public let command: Command

  public var tokens: JoinedTokenSequence {
    switch command {
    case .abort(let keyword, let chain):
      return .compacting(SingleToken.abort, keyword?.asSequence, chain)
    case .startTransaction(let modes):
      return .compacting(SingleToken.start, SingleToken.transaction, modes)
    case .commit(let keyword, let chain):
      return .compacting(SingleToken.commit, keyword?.asSequence, chain)
    case .rollback(let keyword, let chain):
      return .compacting(SingleToken.rollback, keyword?.asSequence, chain)
    case .savePoint(let id):
      return JoinedTokenSequence(SingleToken.savepoint, id.asSequence)
    case .release(let omitSavePointKeyword, let savePointName):
      return .compacting(
        SingleToken.release,
        omitSavePointKeyword ? nil : SingleToken.savepoint,
        savePointName.asSequence
      )
    case .rollbackToSavePoint(let keyword, let omitSavePointKeyword, let savePointName):
      return .compacting(
        SingleToken.rollback,
        keyword?.asSequence,
        SingleToken.to,
        omitSavePointKeyword ? nil : SingleToken.savepoint,
        savePointName.asSequence
      )
    case .prepareTransaction(let transactionID):
      return JoinedTokenSequence(SingleToken.prepare, SingleToken.transaction, transactionID)
    case .commitPrepared(let transactionID):
      return JoinedTokenSequence(SingleToken.commit, SingleToken.prepared, transactionID)
    case .rollbackPrepared(let transactionID):
      return JoinedTokenSequence(SingleToken.rollback, SingleToken.prepared, transactionID)
    }
  }

  private init(_ command: Command) { self.command = command }


  /// Creates `ABORT [ WORK | TRANSACTION ] [ AND [ NO ] CHAIN ]` statement.
  public static func abort(
    _ keyword: TransactionKeyword? = nil,
    and chain: TransactionChain? = nil
  ) -> TransactionStatement {
    return .init(.abort(keyword, chain))
  }

  /// Creates `ABORT` statement.
  public static let abort: TransactionStatement = .abort(nil, and: nil)

  /// Creates `START TRANSACTION [ transaction_mode [, ...] ]` statement
  public static func startTransaction(modes: TransactionModeList?) -> TransactionStatement {
    return .init(.startTransaction(modes))
  }

  /// Creates `START TRANSACTION` statement.
  public static let startTransaction: TransactionStatement = .startTransaction(modes: nil)

  /// Creates `COMMIT [ WORK | TRANSACTION ] [ AND [ NO ] CHAIN ]` statement.
  public static func commit(
    _ keyword: TransactionKeyword? = nil,
    and chain: TransactionChain? = nil
  ) -> TransactionStatement {
    return .init(.commit(keyword, chain))
  }

  /// Creates `COMMIT` statement.
  public static let commit: TransactionStatement = .commit(nil, and: nil)

  /// Creates `ROLLBACK [ WORK | TRANSACTION ] [ AND [ NO ] CHAIN ]` statement.
  public static func rollback(
    _ keyword: TransactionKeyword? = nil,
    and chain: TransactionChain? = nil
  ) -> TransactionStatement {
    return .init(.rollback(keyword, chain))
  }

  /// Creates `ROLLBACK` statement.
  public static let rollback: TransactionStatement = .rollback(nil, and: nil)


  /// Creates `SAVEPOINT savepoint_name` statement.
  public static func savePoint(_ name: ColumnIdentifier) -> TransactionStatement {
    return .init(.savePoint(name))
  }

  /// Creates `RELEASE SAVEPOINT savepoint_name` statement.
  public static func releaseSavePoint(_ savePointName: ColumnIdentifier) -> TransactionStatement {
    return .init(.release(omitSavePointKeyword: false, savePointName: savePointName))
  }

  /// Creates `RELEASE savepoint_name` statement.
  public static func release(_ savePointName: ColumnIdentifier) -> TransactionStatement {
    return .init(.release(omitSavePointKeyword: true, savePointName: savePointName))
  }

  /// Creates `ROLLBACK [ WORK | TRANSACTION ] TO SAVEPOINT savepoint_name` statement.
  public static func rollback(
    _ keyword: TransactionKeyword? = nil,
    toSavePoint name: ColumnIdentifier
  ) -> TransactionStatement {
    return .init(.rollbackToSavePoint(keyword, omitSavePointKeyword: false, savePointName: name))
  }

  /// Creates `ROLLBACK [ WORK | TRANSACTION ] TO savepoint_name` statement.
  public static func rollback(
    _ keyword: TransactionKeyword? = nil,
    to name: ColumnIdentifier
  ) -> TransactionStatement {
    return .init(.rollbackToSavePoint(keyword, omitSavePointKeyword: true, savePointName: name))
  }

  /// Creates `PREPARE TRANSACTION transaction_id` statement.
  public static func prepareTransaction(_ id: StringConstantExpression) -> TransactionStatement {
    return .init(.prepareTransaction(id))
  }

  /// Creates `COMMIT PREPARED transaction_id` statement.
  public static func commitPrepared(_ id: StringConstantExpression) -> TransactionStatement {
    return .init(.commitPrepared(id))
  }

  /// Creates `ROLLBACK PREPARED transaction_id` statement.
  public static func rollbackPrepared(_ id: StringConstantExpression) -> TransactionStatement {
    return .init(.rollbackPrepared(id))
  }
}
