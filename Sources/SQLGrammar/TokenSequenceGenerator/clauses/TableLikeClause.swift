/* *************************************************************************************************
 TableLikeClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option in `LIKE` clause. This is described as `TableLikeOption` in "gram.y".
public enum TableLikeOption: CustomTokenConvertible {
  case comments
  case compression
  case constraints
  case defaults
  case identity
  case generated
  case statistics
  case storage
  case all

  @inlinable
  public var token: Token {
    switch self {
    case .comments:
      return .comments
    case .compression:
      return .compression
    case .constraints:
      return .constraints
    case .defaults:
      return .defaults
    case .identity:
      return .identity
    case .generated:
      return .generated
    case .statistics:
      return .statistics
    case .storage:
      return .storage
    case .all:
      return .all
    }
  }
}


/// A list of `TableLikeOption`s. This is described as `TableLikeOptionList` in "gram.y".
public struct TableLikeOptionList: TokenSequenceGenerator,
                                   InitializableWithNonEmptyList,
                                   ExpressibleByArrayLiteral {
  /// An element of `TableLikeOptionList`.
  public enum Option: TokenSequenceGenerator {
    case including(TableLikeOption)
    case excluding(TableLikeOption)

    @inlinable
    public var tokens: Array<Token> {
      switch self {
      case .including(let option):
        return [.including, option.token]
      case .excluding(let option):
        return [.excluding, option.token]
      }
    }
  }

  public var options: NonEmptyList<Option>

  public var tokens: JoinedSQLTokenSequence {
    return options.joined()
  }

  public init(_ options: NonEmptyList<Option>) {
    self.options = options
  }
}


/// A `LIKE ...` clause that is used in `CREATE TABLE` statement and
/// is described as `TableLikeClause` in "gram.y".
public struct TableLikeClause: Clause {
  public let sourceTable: TableName

  public var options: TableLikeOptionList?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(SingleToken(.like), sourceTable, options)
  }

  public init(like sourceTable: TableName, options: TableLikeOptionList? = nil) {
    self.sourceTable = sourceTable
    self.options = options
  }
}
