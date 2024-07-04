/* *************************************************************************************************
 WithClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Query used in `WITH` clause.
public struct WithQuery: SQLTokenSequence {
  public enum AuxiliaryStatement: SQLTokenSequence {
//    case delete(Delete)
    case insert(Insert)
//    case select(Select)
//    case update(Update)
//    case values(Values)

    public var tokens: [SQLToken] {
      switch self {
      case .insert(let insert):
        return insert.tokens
      }
    }
  }

  /// Optional `SEARCH` clause used in `WITH` clause
  public struct Search: SQLTokenSequence {
    public enum Order {
      case breadthFirst
      case depthFirst
    }

    public var order: Order

    public var columns: [ColumnName]

    public var sequenceColumn: ColumnName

    public var tokens: [SQLToken] {
      var tokens: [SQLToken] = [.search]
      switch order {
      case .breadthFirst:
        tokens.append(contentsOf: [.breadth, .first])
      case .depthFirst:
        tokens.append(contentsOf: [.depth, .first])
      }
      tokens.append(.by)
      tokens.append(contentsOf: columns.map(\.token).joinedByCommas())
      tokens.append(contentsOf: [.set, sequenceColumn.token])
      return tokens
    }

    public init(_ order: Order, by columns: [ColumnName], set sequenceColumn: ColumnName) {
      self.order = order
      self.columns = columns
      self.sequenceColumn = sequenceColumn
    }
  }

  /// Optional `CYCLE` clause used in `WITH` clause.
  public struct Cycle: SQLTokenSequence {
    public struct Mark {
      /// `cycle_mark_value`
      public var value: SQLToken

      /// `cycle_mark_default`
      public var `default`: SQLToken
    }

    public var columns: [ColumnName]

    public var markColumn: ColumnName

    public var mark: Mark?

    public var pathColumn: ColumnName

    public var tokens: [SQLToken] {
      var tokens: [SQLToken] = [.cycle]
      tokens.append(contentsOf: columns.map(\.token).joinedByCommas())
      tokens.append(contentsOf: [.set, markColumn.token])
      mark.map { tokens.append(contentsOf: [.to, $0.value, .default, $0.default]) }
      tokens.append(contentsOf: [.using, pathColumn.token])
      return tokens
    }

    public init(
      _ columns: [ColumnName],
      set markColumn: ColumnName,
      mark: Mark? = nil,
      using pathColumn: ColumnName
    ) {
      self.columns = columns
      self.markColumn = markColumn
      self.mark = mark
      self.pathColumn = pathColumn
    }
  }

  public var name: WithQueryName

  public var columns: [ColumnName]?

  public var isMaterialized: Bool

  public var subquery: AuxiliaryStatement

  public var search: Search?

  public var cycle: Cycle?

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [name.token]
    columns.map {
      tokens.append(contentsOf: [.leftParenthesis, .joiner])
      tokens.append(contentsOf: $0.map(\.token).joinedByCommas())
      tokens.append(contentsOf: [.joiner, .rightParenthesis])
    }
    tokens.append(.as)
    if !isMaterialized {
      tokens.append(contentsOf: [.not, .materialized])
    }
    tokens.append(.leftParenthesis)
    tokens.append(contentsOf: subquery)
    tokens.append(.rightParenthesis)
    search.map { tokens.append(contentsOf: $0) }
    cycle.map { tokens.append(contentsOf: $0) }
    return tokens
  }
}

/// A representation of `WITH` clause.
public struct WithClause: SQLTokenSequence {
  public var isRecursive: Bool

  public var queries: [WithQuery]

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [.with]
    if isRecursive { tokens.append(.recursive) }
    tokens.append(contentsOf: queries.joinedByCommas())
    return tokens
  }

  public init(isRecursive: Bool = false, _ queries: [WithQuery]) {
    self.isRecursive = isRecursive
    self.queries = queries
  }
}
