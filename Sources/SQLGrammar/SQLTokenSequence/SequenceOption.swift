/* *************************************************************************************************
 SequenceOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option of sequence. This is described as `SeqOptElem` in "gram.y".
public struct SequenceOption: SQLTokenSequence {
  private enum _Option {
    case `as`(any SimpleTypeName)
    case cache(any NumericExpression)
    case cycle
    case noCycle
    case increment(omitByKeyword: Bool, increment: any NumericExpression)
    case maxValue(any NumericExpression)
    case minValue(any NumericExpression)
    case noMaxValue
    case noMinValue
    case ownedBy(any AnyName) // name must be `table_name.column_name` or `NONE`
    case sequenceName(any AnyName) // expected to be `SequenceName`
    case start(omitWithKeyword: Bool, start: any NumericExpression)
    case restart((omitWithKeyword: Bool, restart: any NumericExpression)?)
  }

  private let _option: _Option

  public struct Tokens: Sequence {
    public typealias Element = SQLToken

    public struct Iterator: IteratorProtocol {
      public typealias Element = SQLToken
      private let _iterator: AnySQLTokenSequenceIterator
      fileprivate init(_ iterator: AnySQLTokenSequenceIterator) {
        self._iterator = iterator
      }
      public func next() -> SQLToken? { return _iterator.next() }
    }

    private let _tokens: AnySQLTokenSequence

    fileprivate init(_ tokens: AnySQLTokenSequence) {
      self._tokens = tokens
    }

    fileprivate init<S>(_ tokens: S) where S: SQLTokenSequence {
      self._tokens = tokens._asAny
    }

    private init(_ tokens: Array<SQLToken>) {
      self._tokens = UnknownSQLTokenSequence(tokens)._asAny
    }

    public func makeIterator() -> Iterator {
      return Iterator(_tokens.makeIterator())
    }

    public static let cycle: Tokens = .init(SingleToken(.cycle))

    public static let noCycle: Tokens = .init([.no, .cycle])

    public static let noMaxValue: Tokens = .init([.no, .maxvalue])

    public static let noMinValue: Tokens = .init([.no, .minvalue])

    public static let restart: Tokens = .init(SingleToken(.restart))
  }

  public var tokens: Tokens {
    switch _option {
    case .as(let dataType):
      return Tokens(JoinedSQLTokenSequence([SingleToken(.as), dataType]))
    case .cache(let numeric):
      return Tokens(JoinedSQLTokenSequence([SingleToken(.cache), numeric]))
    case .cycle:
      return .cycle
    case .noCycle:
      return .noCycle
    case .increment(let omitByKeyword, let increment):
      return Tokens(JoinedSQLTokenSequence.compacting([
        SingleToken(.increment),
        omitByKeyword ? nil : SingleToken(.by),
        increment
      ]))
    case .maxValue(let numeric):
      return Tokens(JoinedSQLTokenSequence([SingleToken(.maxvalue), numeric]))
    case .minValue(let numeric):
      return Tokens(JoinedSQLTokenSequence([SingleToken(.minvalue), numeric]))
    case .noMaxValue:
      return .noMaxValue
    case .noMinValue:
      return .noMinValue
    case .ownedBy(let anyName):
      return Tokens(JoinedSQLTokenSequence([
        UnknownSQLTokenSequence<Array<SQLToken>>([.owned, .by]),
        anyName
      ]))
    case .sequenceName(let name):
      return Tokens(JoinedSQLTokenSequence([
        UnknownSQLTokenSequence<Array<SQLToken>>([.sequence, .name]),
        name
      ]))
    case .start(let omitWithKeyword, let start):
      return Tokens(JoinedSQLTokenSequence.compacting([
        SingleToken(.start),
        omitWithKeyword ? nil : SingleToken(.with),
        start
      ]))
    case .restart(let optionalArg):
      guard let arg = optionalArg else {
        return .restart
      }
      return Tokens(JoinedSQLTokenSequence.compacting([
        SingleToken(.restart),
        arg.omitWithKeyword ? nil : SingleToken(.with),
        arg.restart
      ]))
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator { return tokens.makeIterator() }

  private init(_ option: _Option) {
    self._option = option
  }

  /// Creates an `AS dataType` option.
  public static func `as`<T>(_ dataType: T) -> SequenceOption where T: SimpleTypeName {
    return SequenceOption(.as(dataType))
  }

  /// Creates a `CACHE cache ` option.
  public static func cache<N>(_ numeric: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.cache(numeric))
  }

  /// Creates a `CACHE cache ` option.
  public static func cache(_ n: UInt) -> SequenceOption {
    return .cache(UnsignedIntegerConstantExpression(n))
  }

  /// Returns a `CYCLE` option.
  public static let cycle: SequenceOption = .init(.cycle)

  /// Returns a `NO CYCLE` option.
  public static let noCycle: SequenceOption = .init(.noCycle)

  /// Creates an `INCREMENT BY increment` option.
  public static func increment<N>(by increment: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.increment(omitByKeyword: false, increment: increment))
  }

  /// Creates an `INCREMENT increment` option.
  public static func increment<N>(_ increment: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.increment(omitByKeyword: true, increment: increment))
  }

  /// Creates a `MAXVALUE value` option.
  public static func maxValue<N>(_ value: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.maxValue(value))
  }

  /// Creates a `MINVALUE value` option.
  public static func minValue<N>(_ value: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.minValue(value))
  }

  /// Returns a `NO MAXVALUE` option.
  public static let noMaxValue: SequenceOption = .init(.noMaxValue)

  /// Returns a `NO MINVALUE` option.
  public static let noMinValue: SequenceOption = .init(.noMinValue)

  /// Creates an `OWNED BY name` option.
  public static func ownedBy(_ column: ColumnReference) -> SequenceOption? {
    guard let columnAsAnyName = column.asAnyName else { return nil }
    return SequenceOption(.ownedBy(columnAsAnyName))
  }

  /// Creates an `OWNED BY table.column` option.
  public static func ownedBy(table: TableName, column: String) -> SequenceOption {
    return .ownedBy(ColumnReference(tableName: table, columnName: column))!
  }

  /// Returns an `OWNED BY NONE` option.
  public static let ownedByNone: SequenceOption = .init(
    .ownedBy(AnyAnyName(identifier: ColumnIdentifier(.none)!))
  )

  /// Creates a `SEQUENCE NAME name` option.
  public static func sequenceName(_ name: SequenceName) -> SequenceOption {
    return SequenceOption(.sequenceName(name))
  }

  /// Creates a `START WITH value` option.
  public static func start<N>(with value: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.start(omitWithKeyword: false, start: value))
  }

  /// Creates a `START value` option.
  public static func start<N>(_ value: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.start(omitWithKeyword: true, start: value))
  }

  /// Returns a `RESTART` option.
  public static let restart: SequenceOption = .init(.restart(nil))

  /// Creates a `RESTART WITH value` option.
  public static func restart<N>(with value: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.restart((omitWithKeyword: false, restart: value)))
  }

  /// Creates a `RESTART value` option.
  public static func restart<N>(_ value: N) -> SequenceOption where N: NumericExpression {
    return SequenceOption(.restart((omitWithKeyword: true, restart: value)))
  }
}

/// A list of `SequenceOption`(a.k.a. `SeqOptElem`). This is described as `SeqOptList` in "gram.y".
public struct SequenceOptionList: SQLTokenSequence,
                                  InitializableWithNonEmptyList,
                                  ExpressibleByArrayLiteral {
  public var options: NonEmptyList<SequenceOption>

  public var tokens: JoinedSQLTokenSequence {
    return options.joined()
  }

  public init(_ options: NonEmptyList<SequenceOption>) {
    self.options = options
  }
}


/// Representation of `OptParenthesizedSeqOptList` in "gram.y".
///
/// This should not be represented by `Optional<SequenceOptionList>`
/// because `OptParenthesizedSeqOptList` must emit parenthesized `SeqOptList` if it has a value.
public enum OptionalSequenceOptionList: SQLTokenSequence,
                                        InitializableWithNonEmptyList,
                                        ExpressibleByNilLiteral,
                                        ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = SequenceOption
  public typealias ArrayLiteralElement = SequenceOption

  case none
  case some(SequenceOptionList)

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken
    private var _iterator: SequenceOptionList.Iterator?
    fileprivate init(_ iterator: SequenceOptionList.Iterator?) {
      self._iterator = iterator
    }
    public mutating func next() -> SQLToken? { return _iterator?.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
    guard case .some(let list) = self else { return Iterator(nil) }
    return Iterator(list.parenthesized.makeIterator())
  }

  @inlinable
  public var isNil: Bool {
    switch self {
    case .none:
      return true
    case .some:
      return false
    }
  }

  @inlinable
  public var sequenceOptiionList: SequenceOptionList? {
    guard case .some(let list) = self else { return nil }
    return list
  }

  public init(nilLiteral: ()) {
    self = .none
  }

  public init(_ list: NonEmptyList<SequenceOption>) {
    self = .some(SequenceOptionList(list))
  }
}
