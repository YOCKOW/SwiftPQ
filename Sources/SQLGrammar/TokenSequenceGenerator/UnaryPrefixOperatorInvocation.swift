/* *************************************************************************************************
 UnaryPrefixOperatorInvocation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents a unary prfeix operator invocation.
public protocol UnaryPrefixOperatorInvocation: TokenSequenceGenerator {
  associatedtype Operator
  associatedtype Operand: TokenSequenceGenerator
  var `operator`: Operator { get }
  var operand: Operand { get }
}

extension UnaryPrefixOperatorInvocation where Self.Operator: Token,
                                              Self.Tokens == JoinedTokenSequence {
  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(self.operator.asSequence, self.operand)
  }
}

extension UnaryPrefixOperatorInvocation where Self.Operator: TokenSequenceGenerator,
                                              Self.Tokens == JoinedTokenSequence {
  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(self.operator, self.operand)
  }
}

// MARK: - '+' operand

/// Representation of "`'+' operand`".
public struct UnaryPrefixPlusOperatorInvocation<Operand>:
  UnaryPrefixOperatorInvocation where Operand: TokenSequenceGenerator
{
  public let `operator`: Token.Operator = .plus

  private let _canOmitSpace: Bool

  public let operand: Operand


  public var tokens: JoinedTokenSequence {
    return .compacting(
      self.operator.asSequence,
      self._canOmitSpace ? SingleToken.joiner : nil,
      self.operand
    )
  }

  private init(operand: Operand, canOmitSpace: Bool) {
    self.operand = operand
    self._canOmitSpace = canOmitSpace
  }

  public init(_ operand: Operand) {
    self.init(operand: operand, canOmitSpace: false)
  }

  public init(_ operand: UnsignedIntegerConstantExpression) where Operand == UnsignedIntegerConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init(_ operand: UnsignedFloatConstantExpression) where Operand == UnsignedFloatConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init<T>(_ operand: Parenthesized<T>) where Operand == Parenthesized<T> {
    self.init(operand: operand, canOmitSpace: true)
  }
}
extension UnaryPrefixPlusOperatorInvocation: Expression, RecursiveExpression where Operand: RecursiveExpression {}
extension UnaryPrefixPlusOperatorInvocation: GeneralExpression where Operand: GeneralExpression {}
extension UnaryPrefixPlusOperatorInvocation: RestrictedExpression where Operand: RestrictedExpression {}

// MARK: - '-' operand

/// Representation of "`'-' operand`".
public struct UnaryPrefixMinusOperatorInvocation<Operand>:
  UnaryPrefixOperatorInvocation where Operand: TokenSequenceGenerator
{
  public let `operator`: Token.Operator = .minus

  private let _canOmitSpace: Bool

  public let operand: Operand


  public var tokens: JoinedTokenSequence {
    return .compacting(
      self.operator.asSequence,
      self._canOmitSpace ? SingleToken.joiner : nil,
      self.operand
    )
  }

  private init(operand: Operand, canOmitSpace: Bool) {
    self.operand = operand
    self._canOmitSpace = canOmitSpace
  }

  public init(_ operand: Operand) {
    self.init(operand: operand, canOmitSpace: false)
  }

  public init(_ operand: UnsignedIntegerConstantExpression) where Operand == UnsignedIntegerConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init(_ operand: UnsignedFloatConstantExpression) where Operand == UnsignedFloatConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init<T>(_ operand: Parenthesized<T>) where Operand == Parenthesized<T> {
    self.init(operand: operand, canOmitSpace: true)
  }
}
extension UnaryPrefixMinusOperatorInvocation: Expression, RecursiveExpression where Operand: RecursiveExpression {}
extension UnaryPrefixMinusOperatorInvocation: GeneralExpression where Operand: GeneralExpression {}
extension UnaryPrefixMinusOperatorInvocation: RestrictedExpression where Operand: RestrictedExpression {}


// MARK: - `qual_Op` operand

/// Representation of `qual_Op a_expr` or `qual_Op b_expr`.
public struct UnaryPrefixQualifiedGeneralOperatorInvocation<Operand>:
  UnaryPrefixOperatorInvocation where Operand: TokenSequenceGenerator 
{
  public typealias Operator = QualifiedGeneralOperator

  public typealias Operand = Operand

  public typealias Tokens = JoinedTokenSequence

  public let `operator`: QualifiedGeneralOperator

  public let operand: Operand

  public init(_ operator: QualifiedGeneralOperator, _ operand: Operand) {
    self.operator = `operator`
    self.operand = operand
  }
}
extension UnaryPrefixQualifiedGeneralOperatorInvocation: 
  Expression, RecursiveExpression where Operand: RecursiveExpression {}
extension UnaryPrefixQualifiedGeneralOperatorInvocation: 
  GeneralExpression where Operand: GeneralExpression {}
extension UnaryPrefixQualifiedGeneralOperatorInvocation: 
  RestrictedExpression where Operand: RestrictedExpression {}


// MARK: - `NOT` operand

/// Logical negation expression that is described as `NOT a_expr` (or `NOT_LA a_expr`) in "gram.y".
public struct UnaryPrefixNotOperatorInvocation<Operand>:
  UnaryPrefixOperatorInvocation, GeneralExpression where Operand: GeneralExpression
{
  public typealias Operator = Token

  public typealias Operand = Operand

  public typealias Tokens = JoinedTokenSequence

  public let `operator`: Token = .not

  public let operand: Operand

  public init(_ operand: Operand) {
    self.operand = operand
  }
}
