/* *************************************************************************************************
 UnaryPrefixOperatorInvocation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents a unary prfeix operator invocation.
public protocol UnaryPrefixOperatorInvocation: SQLTokenSequence {
  associatedtype Operand: SQLTokenSequence
  var `operator`: SQLToken.Operator { get }
  var operand: Operand { get }
}

extension UnaryPrefixOperatorInvocation where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(self.operator.asSequence, self.operand)
  }
}

public struct AnyUnaryPrefixOperatorInvocation: UnaryPrefixOperatorInvocation {
  public typealias Tokens = JoinedSQLTokenSequence

  public struct Operand: SQLTokenSequence {
    public typealias Tokens = Self

    public struct Iterator: IteratorProtocol {
      public typealias Element = SQLToken
      private let _iterator: AnySQLTokenSequenceIterator
      fileprivate init(_ iterator: AnySQLTokenSequenceIterator) { self._iterator = iterator }
      public func next() -> SQLToken? { _iterator.next() }
    }

    private let _sequence: any SQLTokenSequence

    public init<T>(_ sequence: T) where T: SQLTokenSequence {
      self._sequence = sequence
    }

    public func makeIterator() -> Iterator {
      return Iterator(_sequence._asAny.makeIterator())
    }
  }

  public let `operator`: SQLToken.Operator

  public let operand: Operand

  public init(`operator`: SQLToken.Operator, operand: Operand) {
    self.operator = `operator`
    self.operand = operand
  }

  public init<T>(_ other: T) where T: UnaryPrefixOperatorInvocation {
    self.init(operator: other.operator, operand: Operand(other.operand))
  }
}

// MARK: - '+' operand

/// Representation of "`'+' operand`".
public struct UnaryPrefixPlusOperatorInvocation<Operand>:
  UnaryPrefixOperatorInvocation where Operand: SQLTokenSequence
{
  public let `operator`: SQLToken.Operator = .plus

  private let _canOmitSpace: Bool

  public let operand: Operand


  public var tokens: JoinedSQLTokenSequence {
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

  public init(operand: Operand) {
    self.init(operand: operand, canOmitSpace: false)
  }

  public init(operand: UnsignedIntegerConstantExpression) where Operand == UnsignedIntegerConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init(operand: UnsignedFloatConstantExpression) where Operand == UnsignedFloatConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init<T>(operand: Parenthesized<T>) where Operand == Parenthesized<T> {
    self.init(operand: operand, canOmitSpace: true)
  }
}

/// An expression that can be an operand of unary prefix '+'.
public protocol UnaryPrefixPlusOperandExpression: Expression {}
extension UnaryPrefixPlusOperatorInvocation: Expression where Operand: Expression {}
extension UnaryPrefixPlusOperatorInvocation: GeneralExpression where Operand: GeneralExpression {}
extension UnaryPrefixPlusOperatorInvocation: RestrictedExpression where Operand: RestrictedExpression {}

// MARK: - '-' operand

/// Representation of "`'-' operand`".
public struct UnaryPrefixMinusOperatorInvocation<Operand>:
  UnaryPrefixOperatorInvocation where Operand: SQLTokenSequence
{
  public let `operator`: SQLToken.Operator = .minus

  private let _canOmitSpace: Bool

  public let operand: Operand


  public var tokens: JoinedSQLTokenSequence {
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

  public init(operand: Operand) {
    self.init(operand: operand, canOmitSpace: false)
  }

  public init(operand: UnsignedIntegerConstantExpression) where Operand == UnsignedIntegerConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init(operand: UnsignedFloatConstantExpression) where Operand == UnsignedFloatConstantExpression {
    self.init(operand: operand, canOmitSpace: true)
  }

  public init<T>(operand: Parenthesized<T>) where Operand == Parenthesized<T> {
    self.init(operand: operand, canOmitSpace: true)
  }
}

/// An expression that can be an operand of unary prefix '-'.
public protocol UnaryPrefixMinusOperandExpression: Expression {}
extension UnaryPrefixMinusOperatorInvocation: Expression where Operand: Expression {}
extension UnaryPrefixMinusOperatorInvocation: GeneralExpression where Operand: GeneralExpression {}
extension UnaryPrefixMinusOperatorInvocation: RestrictedExpression where Operand: RestrictedExpression {}
