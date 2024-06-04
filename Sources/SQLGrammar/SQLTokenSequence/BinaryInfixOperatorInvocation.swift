/* *************************************************************************************************
 BinaryInfixOperatorInvocation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents a binary infix operator invocation.
public protocol BinaryInfixOperatorInvocation: SQLTokenSequence {
  associatedtype LeftOperand: SQLTokenSequence
  associatedtype RightOperand: SQLTokenSequence

  /// Left operand.
  var leftOperand: LeftOperand { get }

  /// Binary infix operator.
  var `operator`: SQLToken.Operator { get }

  /// Right operand.
  var rightOperand: RightOperand { get }
}

extension BinaryInfixOperatorInvocation where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(self.leftOperand, self.operator.asSequence, self.rightOperand)
  }
}

/// A PostgreSQL-style type-cast syntax like `expression::type`.
public struct BinaryInfixTypeCastOperatorInvocation<Value>:
  BinaryInfixOperatorInvocation where Value: Expression
{
  public typealias LeftOperand = Value

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
