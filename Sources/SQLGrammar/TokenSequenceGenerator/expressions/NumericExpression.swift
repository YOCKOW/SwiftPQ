/* *************************************************************************************************
 NumericExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents some numeric expression that is described as `NumericOnly` in "gram.y".
public protocol NumericExpression: RecursiveExpression {}
extension UnaryPrefixPlusOperatorInvocation: NumericExpression where Operand: NumericExpression {}
extension UnaryPrefixMinusOperatorInvocation: NumericExpression where Operand: NumericExpression {}

/// Signed float expression that is not described directly in "gram.y".
public protocol SignedFloatConstantExpression: NumericExpression {}
extension UnsignedFloatConstantExpression: SignedFloatConstantExpression {}
extension UnaryPrefixPlusOperatorInvocation: SignedFloatConstantExpression where Operand == UnsignedFloatConstantExpression {}
extension UnaryPrefixMinusOperatorInvocation: SignedFloatConstantExpression where Operand == UnsignedFloatConstantExpression {}

/// Signed integer expression that is described as `SignedIconst` in "gram.y".
public protocol SignedIntegerConstantExpression: NumericExpression {}
extension UnsignedIntegerConstantExpression: SignedIntegerConstantExpression {}
extension UnaryPrefixPlusOperatorInvocation: SignedIntegerConstantExpression where Operand == UnsignedIntegerConstantExpression {}
extension UnaryPrefixMinusOperatorInvocation: SignedIntegerConstantExpression where Operand == UnsignedIntegerConstantExpression {}

/// A list of numeric expressions, that is described as `NumericOnly_list` in "gram.y".
public struct NumericExpressionList: TokenSequenceGenerator,
                                     InitializableWithNonEmptyList,
                                     ExpressibleByArrayLiteral {
  public let expressions: NonEmptyList<any NumericExpression>

  public var tokens: JoinedSQLTokenSequence {
    return expressions.map({ $0 as any TokenSequenceGenerator }).joinedByCommas()
  }

  public init(_ expressions: NonEmptyList<any NumericExpression>) {
    self.expressions = expressions
  }
}
