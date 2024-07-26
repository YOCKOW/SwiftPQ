/* *************************************************************************************************
 PartitionBoundSpecification.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `hash_partbound_elem` in "gram.y".
public struct HashPartitionBound: TokenSequenceGenerator {
  public let name: NonReservedWord

  public let value: UnsignedIntegerConstantExpression

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(name.asSequence, value)
  }

  public init(name: NonReservedWord, value: UnsignedIntegerConstantExpression) {
    self.name = name
    self.value = value
  }

  public static func modulus(_ value: UnsignedIntegerConstantExpression) -> HashPartitionBound {
    return .init(name: .modulus, value: value)
  }

  public static func remainder(_ value: UnsignedIntegerConstantExpression) -> HashPartitionBound {
    return .init(name: .remainder, value: value)
  }
}

/// A list of `HashPartitionBound`. This is described as `hash_partbound` in "gram.y".
public struct HashPartitionBoundList: TokenSequenceGenerator,
                                      InitializableWithNonEmptyList,
                                      ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = HashPartitionBound
  public typealias ArrayLiteralElement = HashPartitionBound

  public var bounds: NonEmptyList<HashPartitionBound>

  public var tokens: JoinedSQLTokenSequence {
    return bounds.joinedByCommas()
  }

  @inlinable
  public init(_ bounds: NonEmptyList<HashPartitionBound>) {
    self.bounds = bounds
  }
}

/// Representation of `PartitionBoundSpec` in "gram.y".
public struct PartitionBoundSpecification: TokenSequenceGenerator {
  /// Representation of `partition_bound_expr` in [Official documentation](https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-PARTITION).
  public struct BoundExpression: TokenSequence {
    public let expression: any GeneralExpression

    public struct Iterator: IteratorProtocol {
      public typealias Element = Token
      private let _iterator: AnyTokenSequenceIterator
      fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
      public func next() -> Token? { return _iterator.next() }
    }

    public typealias Tokens = Self

    public func makeIterator() -> Iterator {
      return Iterator(expression._anyIterator)
    }

    public init<Expr>(_ expression: Expr) where Expr: GeneralExpression {
      self.expression = expression
    }

    /// `MINVALUE` as a bound.
    public static let minValue: BoundExpression = .init(
      ColumnReference(identifier: ColumnIdentifier(.minvalue)!)
    )

    /// `MAXVALUE` as a bound.
    public static let maxValue: BoundExpression = .init(
      ColumnReference(identifier: ColumnIdentifier(.maxvalue)!)
    )
  }

  public enum Strategy {
    case hash(HashPartitionBoundList)
    case list(GeneralExpressionList)
    case range(from: GeneralExpressionList, to: GeneralExpressionList)
    case `default`

  }

  public let strategy: Strategy

  private final class _ForValues: TokenSequenceGenerator {
    let tokens: Array<Token> = [.for, .values]
    private init() {}
    static let forValues: _ForValues = .init()
  }

  public var tokens: JoinedSQLTokenSequence {
    switch strategy {
    case .hash(let list):
      return JoinedSQLTokenSequence(_ForValues.forValues, SingleToken.with, list.parenthesized)
    case .list(let list):
      return JoinedSQLTokenSequence(_ForValues.forValues, SingleToken.in, list.parenthesized)
    case .range(let from, let to):
      return JoinedSQLTokenSequence(
        _ForValues.forValues,
        SingleToken.from, from.parenthesized,
        SingleToken.to, to.parenthesized
      )
    case .default:
      return JoinedSQLTokenSequence(SingleToken.default)
    }
  }

  private init(strategy: Strategy) {
    self.strategy = strategy
  }

  /// Creates `FOR VALUES WITH (MODULUS modulus, REMAINDER remainder)` clause.
  public static func forValuesWith(
    modulus: UnsignedIntegerConstantExpression,
    remainder: UnsignedIntegerConstantExpression
  ) -> PartitionBoundSpecification {
    return .init(strategy: .hash([.modulus(modulus), .remainder(remainder)]))
  }

  /// Creates `FOR VALUES IN (expressions)` clause.
  public static func forValuesIn(_ expressions: GeneralExpressionList) -> PartitionBoundSpecification {
    return .init(strategy: .list(expressions))
  }

  /// Creates `FOR VALUES IN (expressions)` clause.
  @inlinable
  public static func forValuesIn(
    _ expressions: NonEmptyList<BoundExpression>
  ) -> PartitionBoundSpecification {
    return .forValuesIn(GeneralExpressionList(expressions.map(\.expression)))
  }

  /// Creates `FOR VALUES FROM (expressions) TO (expressions)` clause.
  public static func forValuesFrom(
    _ from: NonEmptyList<BoundExpression>,
    to: NonEmptyList<BoundExpression>
  ) -> PartitionBoundSpecification {
    return .init(
      strategy: .range(
        from: GeneralExpressionList(from.map(\.expression)),
        to: GeneralExpressionList(to.map(\.expression))
      )
    )
  }

  /// `DEFAULT` partitioning.
  public static let `default`: PartitionBoundSpecification = .init(strategy: .default)
}
