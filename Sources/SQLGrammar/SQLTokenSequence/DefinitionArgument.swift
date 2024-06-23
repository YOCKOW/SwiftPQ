/* *************************************************************************************************
 DefinitionArgument.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A value that is used in key-value pairs for definitions.
/// This is described as `def_arg` in "gram.y".
public struct DefinitionArgument: SQLTokenSequence {
  private enum _Argument {
    case functionType(FunctionType)
    case reservedKeyword(SQLToken.Keyword)
    case qualifiedOperator(QualifiedOperator)
    case numeric(any NumericExpression)
    case stringConstant(StringConstantExpression)
    case none
  }

  private let _argument: _Argument

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken
    private let _iterator: AnySQLTokenSequenceIterator
    fileprivate init(_ iterator: AnySQLTokenSequenceIterator) { self._iterator = iterator }
    public func next() -> SQLToken? { return _iterator.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
    switch _argument {
    case .functionType(let functionType):
      return .init(functionType._asAny.makeIterator())
    case .reservedKeyword(let keyword):
      return .init(keyword.asSequence._asAny.makeIterator())
    case .qualifiedOperator(let qualifiedOperator):
      return .init(qualifiedOperator._asAny.makeIterator())
    case .numeric(let numericExpression):
      return .init(numericExpression._asAny.makeIterator())
    case .stringConstant(let stringConstantExpression):
      return .init(stringConstantExpression._asAny.makeIterator())
    case .none:
      return .init(SingleToken(.none)._asAny.makeIterator())
    }
  }

  public init(_ functionType: FunctionType) {
    self._argument = .functionType(functionType)
  }

  public init?(_ token: SQLToken) {
    guard case let keyword as SQLToken.Keyword = token, keyword.isReserved else { return nil }
    self._argument = .reservedKeyword(keyword)
  }

  public init(_ operator: QualifiedOperator) {
    self._argument = .qualifiedOperator(`operator`)
  }

  public init<N>(_ numeric: N) where N: NumericExpression {
    self._argument = .numeric(numeric)
  }

  public init(_ string: StringConstantExpression) {
    self._argument = .stringConstant(string)
  }

  public init() {
    self._argument = .none
  }

  public static func functionType(_ functionType: FunctionType) -> DefinitionArgument {
    return .init(functionType)
  }

  public static func keyword(_ token: SQLToken) -> DefinitionArgument? {
    return .init(token)
  }

  public static func numeric<N>(_ numeric: N) -> DefinitionArgument where N: NumericExpression {
    return .init(numeric)
  }

  public static func `operator`(_ operator: QualifiedOperator) -> DefinitionArgument {
    return .init(`operator`)
  }

  public static func stringConstant(_ string: StringConstantExpression) -> DefinitionArgument {
    return .init(string)
  }

  public static let none: DefinitionArgument = .init()
}

extension DefinitionArgument {
  /// `TRUE`
  public static let `true`: DefinitionArgument = DefinitionArgument(SQLToken.true)!

  /// `FALSE`
  public static let `false`: DefinitionArgument = DefinitionArgument(SQLToken.false)!
}


extension DefinitionArgument: ExpressibleByBooleanLiteral {
  public typealias BooleanLiteralType = Bool
  public init(booleanLiteral value: Bool) {
    self = value ? .true : .false
  }
}

extension DefinitionArgument: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = UnsignedFloatConstantExpression.FloatLiteralType
  public init(floatLiteral value: FloatLiteralType) {
    if value < 0 {
      let absValue = value * -1
      self.init(UnaryPrefixMinusOperatorInvocation(UnsignedFloatConstantExpression(absValue)!))
    } else {
      self.init(UnsignedFloatConstantExpression(value)!)
    }
  }
}

extension DefinitionArgument: ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = Int
  public init(integerLiteral value: Int) {
    typealias _UInt = UnsignedIntegerConstantExpression.IntegerLiteralType
    if value < 0 {
      let absValue = _UInt(value * -1)
      self.init(UnaryPrefixMinusOperatorInvocation(UnsignedIntegerConstantExpression(absValue)))
    } else {
      self.init(UnsignedIntegerConstantExpression(_UInt(value)))
    }
  }
}

extension DefinitionArgument: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public init(stringLiteral value: String) {
    self.init(StringConstantExpression(stringLiteral: value))
  }
}
