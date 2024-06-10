/* *************************************************************************************************
 BinaryInfixOperatorInvocation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents a binary infix operator invocation.
public protocol BinaryInfixOperatorInvocation: SQLTokenSequence {
  associatedtype LeftOperand: SQLTokenSequence
  associatedtype Operator
  associatedtype RightOperand: SQLTokenSequence

  /// Left operand.
  var leftOperand: LeftOperand { get }

  /// Binary infix operator.
  var `operator`: Operator { get }

  /// Right operand.
  var rightOperand: RightOperand { get }
}

extension BinaryInfixOperatorInvocation where Operator: SQLToken.Operator,
                                              Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(self.leftOperand, self.operator.asSequence, self.rightOperand)
  }
}

extension BinaryInfixOperatorInvocation where Operator: OperatorTokenConvertible,
                                              Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(self.leftOperand, self.operator.asSequence, self.rightOperand)
  }
}

extension BinaryInfixOperatorInvocation where Operator: OperatorTokenSequence,
                                              Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(self.leftOperand, self.operator, self.rightOperand)
  }
}


/// A PostgreSQL-style type-cast syntax like `expression::type`.
public struct BinaryInfixTypeCastOperatorInvocation<Value>:
  BinaryInfixOperatorInvocation where Value: Expression
{
  public typealias LeftOperand = Value

  public typealias Operator = SQLToken.Operator

  public typealias RightOperand = TypeName

  public let value: Value

  public let `operator`: SQLToken.Operator = .typeCast

  public let typeName: TypeName

  public var leftOperand: LeftOperand { value }

  public var rightOperand: RightOperand { typeName }

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      value,
      SingleToken.joiner,
      `operator`.asSequence,
      SingleToken.joiner,
      typeName
    )
  }

  public init(_ value: Value, as typeName: TypeName) {
    self.value = value
    self.typeName = typeName
  }
}
extension BinaryInfixTypeCastOperatorInvocation:
  Expression,
  RecursiveExpression where Value: RecursiveExpression {}
extension BinaryInfixTypeCastOperatorInvocation:
  GeneralExpression where Value: GeneralExpression {}
extension BinaryInfixTypeCastOperatorInvocation:
  RestrictedExpression where Value: RestrictedExpression {}


// MARK: - BinaryInfixMathOperatorInvocation types

/// A type of binary infix operator invocation where the oprator is `MathOp`.
public protocol BinaryInfixMathOperatorInvocation:
  BinaryInfixOperatorInvocation where Self.Operator == MathOperator {}

/// Representation of binary `+` operator invocation.
public struct BinaryInfixPlusOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .plus

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixPlusOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixPlusOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixPlusOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '+' other` expression.
  @inlinable
  public func plus<Other>(
    _ other: Other
  ) -> BinaryInfixPlusOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixPlusOperatorInvocation<Self, Other>(self, other)
  }
}

/// Representation of binary `-` operator invocation.
public struct BinaryInfixMinusOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .minus

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixMinusOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixMinusOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixMinusOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '-' other` expression.
  @inlinable
  public func minus<Other>(
    _ other: Other
  ) -> BinaryInfixMinusOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixMinusOperatorInvocation<Self, Other>(self, other)
  }
}

/// Representation of binary `*` operator invocation.
public struct BinaryInfixMultiplyOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .multiply

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixMultiplyOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixMultiplyOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixMultiplyOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '*' other` expression.
  @inlinable
  public func multiply<Other>(
    _ other: Other
  ) -> BinaryInfixMultiplyOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixMultiplyOperatorInvocation<Self, Other>(self, other)
  }
}

/// Representation of binary `/` operator invocation.
public struct BinaryInfixDivideOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .divide

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixDivideOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixDivideOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixDivideOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '/' other` expression.
  @inlinable
  public func divide<Other>(
    _ other: Other
  ) -> BinaryInfixDivideOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixDivideOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `%` operator invocation.
public struct BinaryInfixModuloOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .modulo

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixModuloOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixModuloOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixModuloOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '%' other` expression.
  @inlinable
  public func modulo<Other>(
    _ other: Other
  ) -> BinaryInfixModuloOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixModuloOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `^` operator invocation.
public struct BinaryInfixExponentOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .exponent

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixExponentOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixExponentOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixExponentOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '^' other` expression.
  @inlinable
  public func exponent<Other>(
    _ other: Other
  ) -> BinaryInfixExponentOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixExponentOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `<` operator invocation.
public struct BinaryInfixLessThanOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .lessThan

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixLessThanOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixLessThanOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixLessThanOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '<' other` expression.
  @inlinable
  public func lessThan<Other>(
    _ other: Other
  ) -> BinaryInfixLessThanOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixLessThanOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `>` operator invocation.
public struct BinaryInfixGreaterThanOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .greaterThan

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixGreaterThanOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixGreaterThanOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixGreaterThanOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '>' other` expression.
  @inlinable
  public func greaterThan<Other>(
    _ other: Other
  ) -> BinaryInfixGreaterThanOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixGreaterThanOperatorInvocation<Self, Other>(self, other)
  }
}

/// Representation of binary `=` operator invocation.
public struct BinaryInfixEqualToOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .equalTo

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixEqualToOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixEqualToOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixEqualToOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '=' other` expression.
  @inlinable
  public func equalTo<Other>(
    _ other: Other
  ) -> BinaryInfixEqualToOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixEqualToOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `<=` operator invocation.
public struct BinaryInfixLessThanOrEqualToOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .lessThanOrEqualTo

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixLessThanOrEqualToOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixLessThanOrEqualToOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixLessThanOrEqualToOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '<=' other` expression.
  @inlinable
  public func lessThanOrEqualTo<Other>(
    _ other: Other
  ) -> BinaryInfixLessThanOrEqualToOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixLessThanOrEqualToOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `>=` operator invocation.
public struct BinaryInfixGreaterThanOrEqualToOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .greaterThanOrEqualTo

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixGreaterThanOrEqualToOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixGreaterThanOrEqualToOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixGreaterThanOrEqualToOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '>=' other` expression.
  @inlinable
  public func greaterThanOrEqualTo<Other>(
    _ other: Other
  ) -> BinaryInfixGreaterThanOrEqualToOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixGreaterThanOrEqualToOperatorInvocation<Self, Other>(self, other)
  }
}


/// Representation of binary `<>` operator invocation.
public struct BinaryInfixNotEqualToOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixMathOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand

  public let leftOperand: LeftOperand

  public let `operator`: MathOperator = .notEqualTo

  public let rightOperand: RightOperand

  public init(_ leftOperand: LeftOperand, _ rightOperand: RightOperand) {
    self.leftOperand = leftOperand
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixNotEqualToOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixNotEqualToOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixNotEqualToOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
extension RecursiveExpression {
  /// Creates a `self '<>' other` expression.
  @inlinable
  public func notEqualTo<Other>(
    _ other: Other
  ) -> BinaryInfixNotEqualToOperatorInvocation<Self, Other> where Other: Expression {
    return BinaryInfixNotEqualToOperatorInvocation<Self, Other>(self, other)
  }
}

// MARK: END OF BinaryInfixMathOperatorInvocation types -


/// An invocation of the qualified general operator (`QualifiedGeneralOperator` a.k.a. `qual_Op`).
public struct BinaryInfixQualifiedGeneralOperatorInvocation<LeftOperand, RightOperand>:
  BinaryInfixOperatorInvocation where LeftOperand: Expression, RightOperand: Expression
{
  public typealias Tokens = JoinedSQLTokenSequence
  public typealias LeftOperand = LeftOperand
  public typealias RightOperand = RightOperand
  public typealias Operator = QualifiedGeneralOperator

  public let leftOperand: LeftOperand

  public let `operator`: QualifiedGeneralOperator

  public let rightOperand: RightOperand

  public init(
    _ leftOperand: LeftOperand,
    _ operator: QualifiedGeneralOperator,
    _ rightOperand: RightOperand
  ) {
    self.leftOperand = leftOperand
    self.operator = `operator`
    self.rightOperand = rightOperand
  }
}
extension BinaryInfixQualifiedGeneralOperatorInvocation:
  Expression,
  RecursiveExpression where LeftOperand: RecursiveExpression,
                            RightOperand: RecursiveExpression {}
extension BinaryInfixQualifiedGeneralOperatorInvocation:
  GeneralExpression where LeftOperand: GeneralExpression,
                          RightOperand: GeneralExpression {}
extension BinaryInfixQualifiedGeneralOperatorInvocation:
  RestrictedExpression where LeftOperand: RestrictedExpression,
                             RightOperand: RestrictedExpression {}
