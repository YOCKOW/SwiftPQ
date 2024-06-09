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

