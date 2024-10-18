/* *************************************************************************************************
 Operator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents an operator described as `all_Op` in "gram.y".
///
/// Conforming types are `MathOperator` and `GeneralOperator`.
public protocol OperatorTokenConvertible: LosslessTokenConvertible where CustomToken == Token.Operator {
  // This requirement should be automatically inherited from the parent protocol,
  // but this initializer cannot be favored from extension without this explicit requirement.
  init?(_ operatorToken: Token.Operator)
}
extension OperatorTokenConvertible {
  public init?(_ token: Token) {
    guard case let operatorToken as Token.Operator = token else { return nil }
    self.init(operatorToken)
  }
}

/// Mathematical operator described as `MathOp` in "gram.y".
public struct MathOperator: OperatorTokenConvertible, Sendable {
  public let token: Token.Operator

  @inlinable
  public init?(_ operatorToken: Token.Operator) {
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

  /// `%` operator.
  public static let modulo: MathOperator = .init(.modulo)!

  /// `^` operator.
  public static let exponent: MathOperator = .init(.exponent)!

  /// `<` operator.
  public static let lessThan: MathOperator = .init(.lessThan)!

  /// `>` operator.
  public static let greaterThan: MathOperator = .init(.greaterThan)!

  /// `=` operator.
  public static let equalTo: MathOperator = .init(.equalTo)!

  /// `<=` operator.
  public static let lessThanOrEqualTo: MathOperator = .init(.lessThanOrEqualTo)!

  /// `>=` operator.
  public static let greaterThanOrEqualTo: MathOperator = .init(.greaterThanOrEqualTo)!

  /// `<>` operator.
  public static let notEqualTo: MathOperator = .init(.notEqualTo)!
}

/// An operator that consists of only one token that is not a math operator.
public struct GeneralOperator: OperatorTokenConvertible, Sendable {
  public let token: Token.Operator

  @inlinable
  public init?(_ operatorToken: Token.Operator) {
    guard !operatorToken.isMathOperator else { return nil }
    self.token = operatorToken
  }
}

/// A token sequence that represents a kind of operator.
public protocol OperatorTokenSequence: TokenSequenceGenerator {}

/// Representation of a schema-qualified operator name that is described as `any_operator`
/// in "gram.y".
public struct LabeledOperator: OperatorTokenSequence, Sendable {
  public let labels: [ColumnIdentifier] // Empty allowed.

  public let `operator`: any OperatorTokenConvertible & Sendable

  public var tokens: JoinedTokenSequence {
    var tokens: [Token] = labels.map(\.token)
    tokens.append(`operator`.token)
    return tokens.joined(separator: dotJoiner)
  }

  public init<Op>(
    labels: [ColumnIdentifier] = [],
    _ `operator`: Op
  ) where Op: OperatorTokenConvertible, Op: Sendable {
    self.labels = labels
    self.operator = `operator`
  }

  public init(labels: [ColumnIdentifier] = [], _ `operator`: Token.Operator) {
    if let mathOp = MathOperator(`operator`) {
      self.init(labels: labels, mathOp)
    } else {
      self.init(labels: labels, GeneralOperator(`operator`)!)
    }
  }

  public init<Op>(schema: SchemaName, _ `operator`: Op) where Op: OperatorTokenConvertible, Op: Sendable {
    self.init(labels: [schema.identifier], `operator`)
  }

  public init(schema: SchemaName, _ `operator`: Token.Operator) {
    self.init(labels: [schema.identifier], `operator`)
  }
}

/// An `OPERATOR` constructor.
public struct OperatorConstructor: OperatorTokenSequence, Sendable {
  public let `operator`: LabeledOperator

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(
      SingleToken.operator, SingleToken.joiner,
      self.operator.parenthesized
    )
  }

  public init(_ `operator`: LabeledOperator) {
    self.operator = `operator`
  }
}

/// Qualified operator described as `qual_all_Op` in "gram.y".
public struct QualifiedOperator: OperatorTokenSequence, Sendable {
  private enum _Type: Sendable {
    case bare(any OperatorTokenConvertible & Sendable)
    case constructor(OperatorConstructor)
  }

  private let _type: _Type

  public init<Op>(_ `operator`: Op) where Op: OperatorTokenConvertible, Op: Sendable {
    self._type = .bare(`operator`)
  }

  public init(_ labeledOperator: LabeledOperator) {
    self._type = .constructor(OperatorConstructor(labeledOperator))
  }

  public init(_ constructor: OperatorConstructor) {
    self._type = .constructor(constructor)
  }

  public struct Tokens: Sequence {
    public struct Iterator: IteratorProtocol {
      public typealias Element = Token

      private var _iterator: AnyTokenSequenceIterator

      fileprivate init(_ qualifiedOperator: QualifiedOperator) {
        switch qualifiedOperator._type {
        case .bare(let someOperator):
          self._iterator = AnyTokenSequenceIterator(
            SingleTokenIterator<Token.Operator>(someOperator.token)
          )
        case .constructor(let operatorConstructor):
          self._iterator = operatorConstructor._anyIterator
        }
      }

      public mutating func next() -> Token? {
        return _iterator.next()
      }
    }
    private let _operator: QualifiedOperator
    fileprivate init(_ operator: QualifiedOperator) { self._operator = `operator` }
    public func makeIterator() -> Iterator {
      return .init(_operator)
    }
  }

  public var tokens: Tokens {
    return Tokens(self)
  }
}

/// Qualified general operator described as `qual_Op` in "gram.y".
public struct QualifiedGeneralOperator: OperatorTokenSequence, Sendable {
  public typealias Tokens = QualifiedOperator.Tokens

  private let _qualifiedOperator: QualifiedOperator

  public var tokens: QualifiedOperator.Tokens { return _qualifiedOperator.tokens }

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


/// An operator that is used in `ANY/SOME/ALL` expression.
/// It is described as `subquery_Op` in "gram.y".
public struct SubqueryOperator: OperatorTokenSequence, Sendable {
  fileprivate enum _Operator: TokenSequenceGenerator {
    /// `all_Op`
    case token(any OperatorTokenConvertible & Sendable)

    /// `OPERATOR '(' any_operator ')'`
    case constructor(OperatorConstructor)

    case like

    case notLike

    case caseInsensitiveLike

    case notCaseInsensitiveLike

    struct Tokens: Sequence {
      struct Iterator: IteratorProtocol {
        typealias Element = Token
        private let _iterator: AnyTokenSequenceIterator
        init(_ iterator: AnyTokenSequenceIterator)  { self._iterator = iterator }
        func next() -> Token? { return _iterator.next() }
      }
      private let _operator: _Operator
      fileprivate init(_ operator: _Operator) { self._operator = `operator` }
      func makeIterator() -> Iterator {
        switch _operator {
        case .token(let op):
          return Iterator(op.asSequence._anyIterator)
        case .constructor(let constructor):
          return Iterator(constructor._anyIterator)
        case .like:
          return Iterator(LikeExpression.Operator.like._anyIterator)
        case .notLike:
          return Iterator(NotLikeExpression.Operator.notLike._anyIterator)
        case .caseInsensitiveLike:
          return Iterator(CaseInsensitiveLikeExpression.Operator.iLike._anyIterator)
        case .notCaseInsensitiveLike:
          return Iterator(NotCaseInsensitiveLikeExpression.Operator.notIlike._anyIterator)
        }
      }
    }

    var tokens: Tokens {
      return Tokens(self)
    }
  }

  private let _operator: _Operator

  public struct Tokens: Sequence {
    public struct Iterator: IteratorProtocol {
      public typealias Element = Token
      private let _iterator: _Operator.Tokens.Iterator
      fileprivate init(_ iterator: _Operator.Tokens.Iterator) { self._iterator = iterator }
      public func next() -> Token? { return _iterator.next() }
    }
    private let _operator: _Operator
    fileprivate init(_ operator: _Operator) { self._operator = `operator` }
    public func makeIterator() -> Iterator {
      return Iterator(_operator.tokens.makeIterator())
    }
  }

  public var tokens: Tokens {
    return Tokens(_operator)
  }

  private init(_operator: _Operator) {
    self._operator = _operator
  }

  public init<Op>(_ `operator`: Op) where Op: OperatorTokenConvertible, Op: Sendable {
    self.init(_operator: .token(`operator`))
  }

  public init(_ constructor: OperatorConstructor) {
    self.init(_operator: .constructor(constructor))
  }

  /// `+` operator.
  public static let plus: SubqueryOperator = .init(MathOperator.plus)

  /// `-` operator.
  public static let minus: SubqueryOperator = .init(MathOperator.minus)

  /// `*` operator.
  public static let multiply: SubqueryOperator = .init(MathOperator.multiply)

  /// `/` operator.
  public static let divide: SubqueryOperator = .init(MathOperator.divide)

  /// `%` operator.
  public static let modulo: SubqueryOperator = .init(MathOperator.modulo)

  /// `^` operator.
  public static let exponent: SubqueryOperator = .init(MathOperator.exponent)

  /// `<` operator.
  public static let lessThan: SubqueryOperator = .init(MathOperator.lessThan)

  /// `>` operator.
  public static let greaterThan: SubqueryOperator = .init(MathOperator.greaterThan)

  /// `=` operator.
  public static let equalTo: SubqueryOperator = .init(MathOperator.equalTo)

  /// `<=` operator.
  public static let lessThanOrEqualTo: SubqueryOperator = .init(MathOperator.lessThanOrEqualTo)

  /// `>=` operator.
  public static let greaterThanOrEqualTo: SubqueryOperator = .init(MathOperator.greaterThanOrEqualTo)

  /// `<>` operator.
  public static let notEqualTo: SubqueryOperator = .init(MathOperator.notEqualTo)
}
