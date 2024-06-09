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

