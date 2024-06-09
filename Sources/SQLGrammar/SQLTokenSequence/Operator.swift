/* *************************************************************************************************
 Operator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents an operator described as `all_Op` in "gram.y".
///
/// Conforming types are `MathOperator` and `GeneralOperator`.
public protocol OperatorTokenConvertible: LosslessTokenConvertible where Token == SQLToken.Operator {
  // This requirement should be automatically inherited from the parent protocol,
  // but this initializer cannot be favored from extension without this explicit requirement.
  init?(_ operatorToken: SQLToken.Operator)
}
extension OperatorTokenConvertible {
  public init?(_ token: SQLToken) {
    guard case let operatorToken as SQLToken.Operator = token else { return nil }
    self.init(operatorToken)
  }
}

/// Mathematical operator described as `MathOp` in "gram.y".
public struct MathOperator: OperatorTokenConvertible {
  public let token: SQLToken.Operator

  @inlinable
  public init?(_ operatorToken: SQLToken.Operator) {
    guard operatorToken.isMathOperator else { return nil }
    self.token = operatorToken
  }

  /// `+` operator.
  public static let plus: MathOperator = .init(.plus)!

  /// `-` operator.
  public static let minus: MathOperator = .init(.minus)!

  /// `*` operator.
  public static let multiply: MathOperator = .init(.multiply)!

  /// `/` operator.
  public static let divide: MathOperator = .init(.divide)!
}

/// An operator that consists of only one token that is not a math operator.
public struct GeneralOperator: OperatorTokenConvertible {
  public let token: SQLToken.Operator

  @inlinable
  public init?(_ operatorToken: SQLToken.Operator) {
    guard !operatorToken.isMathOperator else { return nil }
    self.token = operatorToken
  }
}

/// A token sequence that represents a kind of operator.
public protocol OperatorTokenSequence: SQLTokenSequence {}

/// Representation of a schema-qualified operator name that is described as `any_operator`
/// in "gram.y".
public struct LabeledOperator: OperatorTokenSequence {
  public let labels: [ColumnIdentifier] // Empty allowed.

  public let `operator`: any OperatorTokenConvertible

  public var tokens: JoinedSQLTokenSequence {
    var tokens: [SQLToken] = labels.map(\.token)
    tokens.append(`operator`.token)
    return tokens.joined(separator: dotJoiner)
  }

  public init<Op>(
    labels: [ColumnIdentifier] = [],
    _ `operator`: Op
  ) where Op: OperatorTokenConvertible {
    self.labels = labels
    self.operator = `operator`
  }

  public init(labels: [ColumnIdentifier] = [], _ `operator`: SQLToken.Operator) {
    if let mathOp = MathOperator(`operator`) {
      self.init(labels: labels, mathOp)
    } else {
      self.init(labels: labels, GeneralOperator(`operator`)!)
    }
  }

  public init<Op>(schema: SchemaName, _ `operator`: Op) where Op: OperatorTokenConvertible {
    self.init(labels: [schema.identifier], `operator`)
  }

  public init(schema: SchemaName, _ `operator`: SQLToken.Operator) {
    self.init(labels: [schema.identifier], `operator`)
  }
}

/// An `OPERATOR` constructor.
public struct OperatorConstructor: OperatorTokenSequence {
  public let `operator`: LabeledOperator

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      SingleToken(.operator), SingleToken(.joiner),
      self.operator.parenthesized
    )
  }

  public init(_ `operator`: LabeledOperator) {
    self.operator = `operator`
  }
}

/// Qualified operator described as `qual_all_Op` in "gram.y".
public struct QualifiedOperator: OperatorTokenSequence {
  private enum _Type {
    case bare(any OperatorTokenConvertible)
    case constructor(OperatorConstructor)
  }

  private let _type: _Type

  public init<Op>(_ `operator`: Op) where Op: OperatorTokenConvertible {
    self._type = .bare(`operator`)
  }

  public init(_ labeledOperator: LabeledOperator) {
    self._type = .constructor(OperatorConstructor(labeledOperator))
  }

  public init(_ constructor: OperatorConstructor) {
    self._type = .constructor(constructor)
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken

    private var _iterator: AnySQLTokenSequenceIterator

    fileprivate init(_ qualifiedOperator: QualifiedOperator) {
      switch qualifiedOperator._type {
      case .bare(let someOperator):
        self._iterator = AnySQLTokenSequenceIterator(
          SingleTokenIterator<SQLToken.Operator>(someOperator.token)
        )
      case .constructor(let operatorConstructor):
        self._iterator = AnySQLTokenSequenceIterator(operatorConstructor)
      }
    }

    public mutating func next() -> SQLToken? {
      return _iterator.next()
    }
  }

  public func makeIterator() -> Iterator {
    return .init(self)
  }
}

/// Qualified general operator described as `qual_Op` in "gram.y".
public struct QualifiedGeneralOperator: OperatorTokenSequence {
  public typealias Element = QualifiedOperator.Element
  public typealias Tokens = QualifiedOperator
  public typealias Iterator = QualifiedOperator.Iterator

  private let _qualifiedOperator: QualifiedOperator

  public var tokens: QualifiedOperator { return _qualifiedOperator }

  public func makeIterator() -> QualifiedOperator.Iterator {
    return _qualifiedOperator.makeIterator()
  }

  public init(_ generalOperator: GeneralOperator) {
    self._qualifiedOperator = .init(generalOperator)
  }

  public init(_ labeledOperator: LabeledOperator) {
    self._qualifiedOperator = .init(labeledOperator)
  }

  public init(_ constructor: OperatorConstructor) {
    self._qualifiedOperator = .init(constructor)
  }
}
