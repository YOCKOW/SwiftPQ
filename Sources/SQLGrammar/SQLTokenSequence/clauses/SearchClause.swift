/* *************************************************************************************************
 SearchClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `SEARCH` clause  that is described as `opt_search_clause` in "gram.y".
public struct SearchClause: Clause {
  public enum Ordering: Clause {
    case depthFirst
    case breadthFirst

    private static let _depthFirstTokens: Array<SQLToken> = [.depth, .first]
    private static let _breadthFirstTokens: Array<SQLToken> = [.breadth, .first]

    public var tokens: Array<SQLToken> {
      switch self {
      case .depthFirst:
        return Ordering._depthFirstTokens
      case .breadthFirst:
        return Ordering._breadthFirstTokens
      }
    }
  }

  public let ordering: Ordering

  public let columnNames: ColumnList

  public let searchSequenceColumnName: ColumnIdentifier

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      SingleToken(.search),
      ordering,
      SingleToken(.by),
      columnNames,
      SingleToken(.set),
      searchSequenceColumnName.asSequence
    )
  }

  public init(
    _ ordering: Ordering,
    by columnNames: ColumnList,
    set searchSequenceColumnName: ColumnIdentifier
  ) {
    self.ordering = ordering
    self.columnNames = columnNames
    self.searchSequenceColumnName = searchSequenceColumnName
  }
}
