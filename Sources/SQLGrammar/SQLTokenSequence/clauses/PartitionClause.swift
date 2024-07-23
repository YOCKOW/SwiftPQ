/* *************************************************************************************************
 PartitionClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private final class PartitionBy: Segment {
  let tokens: Array<SQLToken> = [.partition, .by]
  private init() {}
  static let partitionBy: PartitionBy = .init()
}

/// A clause that is described as `opt_partition_clause` in "gram.y".
///
/// This is different from `ParticionSpecification` which is used in `CREATE TABLE ...` statement.
public struct PartitionClause: Clause {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(PartitionBy.partitionBy, expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }
}

/// A parameter of partition specifitcation. This is described as `part_elem` in "gram.y".
public struct PartitionSpecificationParameter: SQLTokenSequence {
  private enum _NameOrExpression: SQLTokenSequence {
    case name(ColumnIdentifier)
    case funcExpression(any WindowlessFunctionExpression)
    case generalExpression(any GeneralExpression)

    var tokens: AnySQLTokenSequence {
      switch self {
      case .name(let columnIdentifier):
        return columnIdentifier.asSequence._asAny
      case .funcExpression(let windowlessFunctionExpression):
        return windowlessFunctionExpression._asAny
      case .generalExpression(let generalExpression):
        return generalExpression._asAny.parenthesized._asAny
      }
    }

    func makeIterator() -> AnySQLTokenSequenceIterator {
      return tokens.makeIterator()
    }
  }

  private let _nameOrExpression: _NameOrExpression

  public var columnName: ColumnIdentifier? {
    guard case .name(let id) = _nameOrExpression else { return nil }
    return id
  }

  public var expression: (any Expression)? {
    switch _nameOrExpression {
    case .name:
      return nil
    case .funcExpression(let windowlessFunctionExpression):
      return windowlessFunctionExpression
    case .generalExpression(let generalExpression):
      return generalExpression
    }
  }

  public let collation: CollateClause?

  public let operatorClass: OperatorClass?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(_nameOrExpression, collation, operatorClass)
  }

  public init(
    columnName: ColumnIdentifier,
    collation: CollateClause? = nil,
    operatorClass: OperatorClass? = nil
  ) {
    self._nameOrExpression = .name(columnName)
    self.collation = collation
    self.operatorClass = operatorClass
  }

  public init<E>(
    expression: E,
    collation: CollateClause? = nil,
    operatorClass: OperatorClass? = nil
  ) where E: WindowlessFunctionExpression {
    self._nameOrExpression = .funcExpression(expression)
    self.collation = collation
    self.operatorClass = operatorClass
  }

  public init<E>(
    expression: E,
    collation: CollateClause? = nil,
    operatorClass: OperatorClass? = nil
  ) where E: GeneralExpression {
    self._nameOrExpression = .generalExpression(expression)
    self.collation = collation
    self.operatorClass = operatorClass
  }
}

/// A list of `PartitionSpecificationParameter`s. This is described as `part_params` in "gram.y".
public struct PartitionSpecificationParameterList: SQLTokenSequence,
                                                   InitializableWithNonEmptyList,
                                                   ExpressibleByArrayLiteral {
  public let parameters: NonEmptyList<PartitionSpecificationParameter>

  public var tokens: JoinedSQLTokenSequence {
    return parameters.joinedByCommas()
  }

  public init(_ parameters: NonEmptyList<PartitionSpecificationParameter>) {
    self.parameters = parameters
  }
}

/// Partitioning strategy.
///
/// While this is defined as `ColId`, there are a few tokens that can be accepted here:
/// [Source](https://github.com/postgres/postgres/blob/REL_16_3/src/backend/parser/gram.y#L18726-L18746).
public enum PartitionStrategy: CustomTokenConvertible {
  case range
  case list
  case hash

  @inlinable
  public var token: SQLToken {
    switch self {
    case .range:
      return .range
    case .list:
      return .identifier("LIST")
    case .hash:
      return .identifier("HASH")
    }
  }
}

/// `PARTITION BY ...` clause described as `PartitionSpec` in "gram.y".
///
/// This is different from `ParticionClause` which is used in
/// `WindowSpecification` while this (`PartitionSpecification`) is used in `CREATE TABLE ...`
/// statement.
public struct PartitionSpecification: Clause {
  public let strategy: PartitionStrategy

  public let parameters: PartitionSpecificationParameterList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      PartitionBy.partitionBy,
      strategy.asSequence,
      parameters.parenthesized
    )
  }

  public init(strategy: PartitionStrategy, parameters: PartitionSpecificationParameterList) {
    self.strategy = strategy
    self.parameters = parameters
  }
}
