/* *************************************************************************************************
 SQLTokenSequence+Sort(OrderBy).swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public protocol SortDirectionProtocol {
  var tokens: [SQLToken] { get }
}

/// Sort direction used in `SELECT`.
public enum SortDirection: SortDirectionProtocol {
  case ascending
  case descending
  public static let `default`: SortDirection = .ascending


  public var token: SQLToken {
    switch self {
    case .ascending:
      return .asc
    case .descending:
      return .desc
    }
  }
  public var tokens: [SQLToken] {
    return [token]
  }
}

/// Sort direction used in "window definition".
public enum WindowDefinitionSortDirection: SortDirectionProtocol {
  case ascending
  case descending
  case `operator`(SQLToken.Operator)

  public var tokens: [SQLToken] {
    switch self {
    case .ascending:
      return [.asc]
    case .descending:
      return [.desc]
    case .operator(let op):
      return [.using, op]
    }
  }
}

public enum NullOrdering {
  case first
  case last

  internal var token: SQLToken {
    switch self {
    case .first:
      return .first
    case .last:
      return .last
    }
  }
}

public protocol SorterProtocol: SQLTokenSequence {
  associatedtype Direction: SortDirectionProtocol
  var expression: any SQLTokenSequence { get set }
  var direction: Direction? { get set }
  var nullOrdering: NullOrdering? { get set }
}

extension SorterProtocol {
  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = expression.tokens
    if let direction {
      tokens.append(contentsOf: direction.tokens)
    }
    nullOrdering.map { tokens.append(contentsOf: [.nulls, $0.token]) }
    return tokens
  }
}

public protocol SortClauseProtocol: SQLTokenSequence {
  associatedtype Sorter: SorterProtocol
  var sorters: [Sorter] { get }
  init(_ sorters: [Sorter]) throws
}

extension SortClauseProtocol {
  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [.order, .by]
    tokens.append(contentsOf: sorters.joined(separator: [.joiner, .comma]))
    return tokens
  }

  public init(_ sorters: Sorter...) throws {
    try self.init(sorters)
  }
}

public enum SortClauseInitializationError: Error {
  case emptySorters
}

/// A type that represents `ORDER BY ...` in `SELECT`.
public struct SortClause: SortClauseProtocol {
  /// A type that represents `sort_expression [ASC | DESC] [NULLS { FIRST | LAST }]`
  public struct Sorter: SorterProtocol {
    public typealias Direction = SortDirection

    public var expression: any SQLTokenSequence

    public var direction: Direction?

    public var nullOrdering: NullOrdering?

    public init(_ expression: any SQLTokenSequence, direction: Direction? = nil, nullOrdering: NullOrdering? = nil) {
      self.expression = expression
      self.direction = direction
      self.nullOrdering = nullOrdering
    }
  }

  public let sorters: [Sorter]

  public init(_ sorters: [Sorter]) throws {
    if sorters.isEmpty {
      throw SortClauseInitializationError.emptySorters
    }
    self.sorters = sorters
  }
}

/// A type that represents `ORDER BY ...` in window definition.
public struct WindowDefinitionSortClause: SortClauseProtocol {
  /// A type that represents `ORDER BY expression [ ASC | DESC | USING operator ] [ NULLS { FIRST | LAST } ]`
  public struct Sorter: SorterProtocol {
    public typealias Direction = WindowDefinitionSortDirection

    public var expression: any SQLTokenSequence

    public var direction: Direction?

    public var nullOrdering: NullOrdering?

    public init(_ expression: any SQLTokenSequence, direction: Direction? = nil, nullOrdering: NullOrdering? = nil) {
      self.expression = expression
      self.direction = direction
      self.nullOrdering = nullOrdering
    }
  }

  public let sorters: [Sorter]

  public init(_ sorters: [Sorter]) throws {
    if sorters.isEmpty {
      throw SortClauseInitializationError.emptySorters
    }
    self.sorters = sorters
  }
}
