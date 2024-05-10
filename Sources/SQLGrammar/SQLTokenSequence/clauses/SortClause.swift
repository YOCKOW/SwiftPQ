/* *************************************************************************************************
 SortClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Sort direction.
public enum SortDirection: LosslessTokenConvertible {
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

  public init?(_ token: SQLToken) {
    guard case let keyword as SQLToken.Keyword = token else { return nil }
    if keyword == .asc {
      self = .ascending
    } else if keyword == .desc {
      self = .descending
    } else {
      return nil
    }
  }
}

/// A type that represents nulls order.
public enum NullOrdering: Segment {
  /// NULLS FIRST
  case first

  /// NULLS LAST
  case last

  private static let _nullsFirst: Array<SQLToken> = [.nulls, .first]
  private static let _nullsLast: Array<SQLToken> = [.nulls, .last]

  public var tokens: Array<SQLToken> {
    switch self {
    case .first:
      return Self._nullsFirst
    case .last:
      return Self._nullsLast
    }
  }
}

/// Representation of an expression to sort. It is described as `sortby` in "gram.y".
public struct SortBy<Expression>: SQLTokenSequence where Expression: GeneralExpression {
  public enum Sorter {
    /// A keyword `ASC` or `DESC`
    case direction(SortDirection)

    /// `USING` clause.
    case `operator`(QualifiedOperator)
  }

  public let expression: Expression

  public let sorter: Sorter?

  public let nullOrdering: NullOrdering?

  public var tokens: JoinedSQLTokenSequence {
    var sequences: [any SQLTokenSequence] = [expression]

    switch sorter {
    case .direction(let sortDirection):
      sequences.append(SingleToken(sortDirection))
    case .operator(let qualifiedOperator):
      sequences.append(SingleToken(.using))
      sequences.append(qualifiedOperator)
    case nil:
      break
    }

    nullOrdering.map({ sequences.append($0) })

    return JoinedSQLTokenSequence(sequences)
  }

  public init(_ expression: Expression, sorter: Sorter? = nil, nullOrdering: NullOrdering? = nil) {
    self.expression = expression
    self.sorter = sorter
    self.nullOrdering = nullOrdering
  }

  public init(
    _ expression: Expression,
    direction: SortDirection,
    nullOrdering: NullOrdering? = nil
  ) {
    self.init(expression, sorter: .direction(direction), nullOrdering: nullOrdering)
  }

  public init(
    _ expression: Expression,
    using operator: QualifiedOperator,
    nullOrdering: NullOrdering? = nil
  ) {
    self.init(expression, sorter: .operator(`operator`), nullOrdering: nullOrdering)
  }
}

private struct _AnySortBy: SQLTokenSequence {
  class _Box {
    var tokens: JoinedSQLTokenSequence { fatalError("Must be overridden.") }
  }

  class _Base<T>: _Box where T: GeneralExpression {
    let _base: SortBy<T>
    init(_ base: SortBy<T>) { self._base = base }
    override var tokens: JoinedSQLTokenSequence { return _base.tokens }
  }

  private let _box: _Box

  var tokens: JoinedSQLTokenSequence { _box.tokens }

  init<T>(_ sortBy: SortBy<T>) where T: GeneralExpression {
    self._box = _Base<T>(sortBy)
  }
}

final class OrderBy: Segment {
  let tokens: [SQLToken] = [.order, .by]
  static let orderBy: OrderBy = .init()
}

/// A type that represents `ORDER BY` clause described as `sort_clause` in "gram.y".
public struct SortClause: Clause {
  /// A list of `SortBy` instances. It is described as `sortby_list` in "gram.y".
  public struct List: SQLTokenSequence {
    private var _list: NonEmptyList<_AnySortBy>

    public init<FirstSortByExpr, each OptionalSortByExpr>(
      _ firstSortBy: SortBy<FirstSortByExpr>,
      _ optionalSortBy: repeat SortBy<each OptionalSortByExpr>
    ) where FirstSortByExpr: GeneralExpression, repeat each OptionalSortByExpr: GeneralExpression {
      var list = NonEmptyList<_AnySortBy>(item: _AnySortBy(firstSortBy))
      repeat (list.append(_AnySortBy(each optionalSortBy)))
      self._list = list
    }

    public mutating func append<Expr>(_ sortBy: SortBy<Expr>) where Expr: GeneralExpression {
      _list.append(_AnySortBy(sortBy))
    }

    public var tokens: JoinedSQLTokenSequence {
      return _list.joinedByCommas()
    }
  }

  public var list: List

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(OrderBy.orderBy, list)
  }

  public init(_ list: List) {
    self.list = list
  }

  public init<FirstSortByExpr, each OptionalSortByExpr>(
    _ firstSortBy: SortBy<FirstSortByExpr>,
    _ optionalSortBy: repeat SortBy<each OptionalSortByExpr>
  ) where FirstSortByExpr: GeneralExpression, repeat each OptionalSortByExpr: GeneralExpression {
    var list = List(firstSortBy)
    repeat (list.append(each optionalSortBy))
    self.init(list)
  }
}
