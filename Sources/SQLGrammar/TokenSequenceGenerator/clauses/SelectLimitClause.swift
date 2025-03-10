/* *************************************************************************************************
 SelectLimitClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A value used in `LIMIT` clause. It is described as `select_limit_value` in "gram.y".
public enum SelectLimitValue: TokenSequence {
  /// The maximum number of rows to return.
  case count(any GeneralExpression)
  case all

  public struct Iterator: IteratorProtocol {
    public typealias Element = Token
    private let _iterator: AnyTokenSequenceIterator
    fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
    public func next() -> Token? { _iterator.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
    switch self {
    case .count(let count):
      return Iterator(count._anyIterator)
    case .all:
      return Iterator(AnyTokenSequenceIterator(SingleToken.all))
    }
  }

  public init(_ value: UnsignedIntegerConstantExpression) {
    self = .count(value)
  }
}

/// A value used in `OFFSET` clause or `LIMIT` clause.
/// It is described as `select_offset_value` in "gram.y".
public struct SelectOffsetValue: TokenSequence {
  public let value: any GeneralExpression

  public struct Iterator: IteratorProtocol {
    public typealias Element = Token
    private let _iterator: AnyTokenSequenceIterator
    fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
    public func next() -> Token? { _iterator.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
    return Iterator(value._anyIterator)
  }

  public init(_ value: any GeneralExpression) {
    self.value = value
  }

  public init(_ value: UnsignedIntegerConstantExpression) {
    self.value = value
  }
}


/// `LIMIT ...` or `FETCH ...` clause that is described as `limit_clause` in "gram.y".
public struct LimitClause: Clause {
  /// `FETCH ...` clause that is a kind of `limit_clause`.
  public struct FetchClause: Clause {
    /// A (ignorable) keyword for `FETCH` clause, that is described as `first_or_next` in "gram.y".
    public enum Keyword: CustomTokenConvertible, Sendable {
      case first
      case next

      public var token: Token {
        switch self {
        case .first:
          return .first
        case .next:
          return .next
        }
      }
    }

    /// An expression for row count that is described as `select_fetch_first_value` in "gram.y".
    public struct RowCount: TokenSequenceGenerator {
      public let value: any TokenSequenceGenerator

      public struct Tokens: Sequence {
        public struct Iterator: IteratorProtocol {
          public typealias Element = Token
          private let _iterator: AnyTokenSequenceIterator
          fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
          public func next() -> Token? { _iterator.next() }
        }

        private let _count: RowCount
        fileprivate init(_ count: RowCount) { self._count = count }
        public func makeIterator() -> Iterator { return Iterator(_count.value._anyIterator) }
      }

      public var tokens: Tokens {
        return Tokens(self)
      }

      public init<T>(_ value: T) where T: ProductionExpression {
        self.value = value
      }

      public init(_ value: UnaryPrefixPlusOperatorInvocation<UnsignedIntegerConstantExpression>) {
        self.value = value
      }

      public init(_ value: UnaryPrefixMinusOperatorInvocation<UnsignedIntegerConstantExpression>) {
        self.value = value
      }


      public init(_ value: UnaryPrefixPlusOperatorInvocation<UnsignedFloatConstantExpression>) {
        self.value = value
      }

      public init(_ value: UnaryPrefixMinusOperatorInvocation<UnsignedFloatConstantExpression>) {
        self.value = value
      }

      fileprivate var _unit: Unit {
        switch value {
        case let intConstExpr as UnsignedIntegerConstantExpression where intConstExpr.token.isOne:
          return .row
        case let floatConstExpr as UnsignedFloatConstantExpression where floatConstExpr.token.isOne:
          return .row
        default:
          return .rows
        }
      }
    }

    /// A (ignorable) token `ROW` or `ROWS` that is described as `row_or_rows` in "gram.y".
    public enum Unit: CustomTokenConvertible, Sendable {
      case row
      case rows

      public var token: Token {
        switch self {
        case .row:
          return .row
        case .rows:
          return .rows
        }
      }
    }

    /// An option for `FETCH` clause that is either `ONLY` or `WITH TIES`.
    public enum Option: Segment {
      case only
      case withTies

      public var tokens: Array<Token> {
        switch self {
        case .only:
          return [.only]
        case .withTies:
          return [.with, .ties]
        }
      }
    }

    public let keyword: Keyword

    public let count: RowCount?

    public let unit: Unit

    public let option: Option

    public var tokens: JoinedTokenSequence {
      return .compacting([
        SingleToken.fetch,
        keyword.asSequence,
        count,
        unit.asSequence,
        option,
      ])
    }

    public init(
      _ keyword: Keyword = .next,
      count: RowCount?,
      unit: Unit? = nil,
      option: Option
    ) {
      self.keyword = keyword
      self.count = count
      self.unit = unit ?? count?._unit ?? .rows
      self.option = option
    }
  }

  private enum _Type {
    case limit(count: SelectLimitValue, offset: SelectOffsetValue?)
    case fetch(FetchClause)
  }

  private let _type: _Type

  fileprivate var _isFetch: Bool {
    guard case .fetch = _type else {
      return false
    }
    return true
  }

  public var tokens: JoinedTokenSequence {
    switch _type {
    case .limit(let count, let offset):
      return .compacting(
        SingleToken.limit,
        count,
        offset.map({
          JoinedTokenSequence(commaSeparator, $0)
        })
      )
    case .fetch(let fetchClause):
      return fetchClause.tokens
    }
  }

  private init(_type: _Type) {
    self._type = _type
  }

  public static func limit(count: SelectLimitValue, offset: SelectOffsetValue? = nil) -> LimitClause {
    return .init(_type: .limit(count: count, offset: offset))
  }

  public static func fetch(_ clause: FetchClause) -> LimitClause {
    return .init(_type: .fetch(clause))
  }

  public static func fetch(
    _ keyword: FetchClause.Keyword = .next,
    count: FetchClause.RowCount?,
    unit: FetchClause.Unit? = nil,
    option: FetchClause.Option
  ) -> LimitClause {
    return .init(_type: .fetch(.init(keyword, count: count, unit: unit, option: option)))
  }
}

/// `OFFSET ...` clause that is described as `offset_clause` in "gram.y".
public struct OffsetClause: Clause {
  private enum _Value {
    case offset(SelectOffsetValue)
    case rowCount(LimitClause.FetchClause.RowCount, LimitClause.FetchClause.Unit)
  }

  private let _value: _Value

  public var value: any TokenSequenceGenerator {
    switch _value {
    case .offset(let offset):
      return offset.value
    case .rowCount(let rowCount, _):
      return rowCount.value
    }
  }

  public var tokens: JoinedTokenSequence {
    switch _value {
    case .offset(let offset):
      return JoinedTokenSequence([SingleToken.offset, offset])
    case .rowCount(let rowCount, let unit):
      return JoinedTokenSequence([SingleToken.offset, rowCount, unit.asSequence])
    }
  }

  public init(_ value: SelectOffsetValue) {
    self._value = .offset(value)
  }

  public init(
    _ value: LimitClause.FetchClause.RowCount,
    _ unit: LimitClause.FetchClause.Unit? = nil
  ) {
    self._value = .rowCount(value, unit ?? value._unit)
  }
}


/// A clause that consists of two independent sub-clauses (`LIMIT` and `OFFSET`).
/// It is described as `select_limit` in "gram.y"
public struct SelectLimitClause: Clause {
  public let limit: LimitClause?

  public let offset: OffsetClause?

  private enum _ClauseOrder {
    case limitOffset
    case offsetLimit
  }

  private let _order: _ClauseOrder

  public var tokens: JoinedTokenSequence {
    assert(limit != nil || offset != nil)
    switch _order {
    case .limitOffset:
      return .compacting(limit, offset)
    case .offsetLimit:
      return .compacting(offset, limit)
    }
  }

  private init(limit: LimitClause?, offset: OffsetClause?, order: _ClauseOrder) {
    self.limit = limit
    self.offset = offset
    self._order = order
  }

  public init(limit: LimitClause, offset: OffsetClause?) {
    self.init(limit: limit, offset: offset, order: limit._isFetch ? .offsetLimit : .limitOffset)
  }

  /// Creates a clause like `LIMIT { count | ALL } OFFSET start`.
  public static func limit(count: SelectLimitValue, offset: SelectOffsetValue) -> SelectLimitClause {
    return SelectLimitClause(
      limit: .limit(count: count),
      offset: OffsetClause(offset),
      order: .limitOffset
    )
  }

  /// Creates a clause like `OFFSET start { ROW | ROWS }`
  /// `FETCH { FIRST | NEXT } [ count ] { ROW | ROWS } { ONLY | WITH TIES }`.
  public static func offset(
    _ start: LimitClause.FetchClause.RowCount,
    _ offsetUnit: LimitClause.FetchClause.Unit? = nil,
    fetch keyword: LimitClause.FetchClause.Keyword = .next,
    _ count: LimitClause.FetchClause.RowCount?,
    _ fetchUnit: LimitClause.FetchClause.Unit? = nil,
    option: LimitClause.FetchClause.Option
  ) -> SelectLimitClause {
    return SelectLimitClause(
      limit: .fetch(keyword, count: count, unit: fetchUnit, option: option),
      offset: OffsetClause(start, offsetUnit),
      order: .offsetLimit
    )
  }
}
