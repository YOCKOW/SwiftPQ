/* *************************************************************************************************
 Definition.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A value that is used in key-value pairs for definitions.
/// This is described as `def_arg` in "gram.y".
public struct DefinitionArgument: TokenSequence {
  private enum _Argument {
    case functionType(FunctionType)
    case reservedKeyword(Token.Keyword)
    case qualifiedOperator(QualifiedOperator)
    case numeric(any NumericExpression)
    case stringConstant(StringConstantExpression)
    case none
  }

  private let _argument: _Argument

  public struct Iterator: IteratorProtocol {
    public typealias Element = Token
    private let _iterator: AnyTokenSequenceIterator
    fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
    public func next() -> Token? { return _iterator.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
    switch _argument {
    case .functionType(let functionType):
      return .init(functionType._anyIterator)
    case .reservedKeyword(let keyword):
      return .init(keyword.asSequence._anyIterator)
    case .qualifiedOperator(let qualifiedOperator):
      return .init(qualifiedOperator._anyIterator)
    case .numeric(let numericExpression):
      return .init(numericExpression._anyIterator)
    case .stringConstant(let stringConstantExpression):
      return .init(stringConstantExpression._anyIterator)
    case .none:
      return .init(SingleToken.none._anyIterator)
    }
  }

  public init(_ functionType: FunctionType) {
    self._argument = .functionType(functionType)
  }

  public init?(_ token: Token) {
    guard case let keyword as Token.Keyword = token, keyword.isReserved else { return nil }
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

  public static func keyword(_ token: Token) -> DefinitionArgument? {
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
  public static let `true`: DefinitionArgument = DefinitionArgument(Token.true)!

  /// `FALSE`
  public static let `false`: DefinitionArgument = DefinitionArgument(Token.false)!
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


/// A pair of a key and an optional value. This is `def_elem` in "gram.y".
public struct DefinitionElement: TokenSequenceGenerator {
  public struct Key: TokenSequenceGenerator, ExpressibleByStringLiteral {
    public let key: ColumnLabel
    public var tokens: Array<Token> {
      return [key.token]
    }
    public init(_ key: ColumnLabel) {
      self.key = key
    }
    public init(stringLiteral value: StringLiteralType) {
      self.key = .init(stringLiteral: value)
    }
  }

  public struct Value: TokenSequenceGenerator {
    public let value: DefinitionArgument

    public typealias Tokens = DefinitionArgument.Tokens

    public var tokens: Tokens {
      return value.tokens
    }

    public init(_ value: DefinitionArgument) {
      self.value = value
    }
  }

  public let key: Key

  public let value: Value?

  public var tokens: JoinedTokenSequence {
    return .compacting(key, value, separator: SingleToken(Token.Operator.equalTo))
  }

  public init(key: Key, value: Value? = nil) {
    self.key = key
    self.value = value
  }
}

extension DefinitionElement.Value: ExpressibleByBooleanLiteral,
                                   ExpressibleByFloatLiteral,
                                   ExpressibleByIntegerLiteral,
                                   ExpressibleByStringLiteral {
  public typealias BooleanLiteralType = DefinitionArgument.BooleanLiteralType
  public typealias FloatLiteralType = DefinitionArgument.FloatLiteralType
  public typealias IntegerLiteralType = DefinitionArgument.IntegerLiteralType
  public typealias StringLiteralType = DefinitionArgument.StringLiteralType

  @inlinable
  public init(booleanLiteral value: BooleanLiteralType) {
    self.init(DefinitionArgument(booleanLiteral: value))
  }

  @inlinable
  public init(floatLiteral value: FloatLiteralType) {
    self.init(DefinitionArgument(floatLiteral: value))
  }

  @inlinable
  public init(integerLiteral value: IntegerLiteralType) {
    self.init(DefinitionArgument(integerLiteral: value))
  }

  @inlinable
  public init(stringLiteral value: StringLiteralType) {
    self.init(DefinitionArgument(stringLiteral: value))
  }
}

/// A list of `DefinitionElement`. This is described as `def_list` in "gram.y".
public struct DefinitonList: TokenSequenceGenerator,
                             InitializableWithNonEmptyList,
                             ExpressibleByArrayLiteral,
                             ExpressibleByDictionaryLiteral {
  public typealias NonEmptyListElement = DefinitionElement
  public typealias ArrayLiteralElement = DefinitionElement
  public typealias Key = DefinitionElement.Key
  public typealias Value = DefinitionElement.Value?

  public var parameters: NonEmptyList<DefinitionElement>

  public var tokens: JoinedTokenSequence {
    return parameters.joinedByCommas()
  }

  public init(_ parameters: NonEmptyList<DefinitionElement>) {
    self.parameters = parameters
  }

  public init(dictionaryLiteral elements: (DefinitionElement.Key, DefinitionElement.Value?)...) {
    guard let list = NonEmptyList<DefinitionElement>(
      items: elements.map({ DefinitionElement(key: $0.0, value: $0.1) })
    ) else {
      fatalError("Empty list not allowed.")
    }
    self.init(list)
  }
}

/// `definition` in "gram.y".
public struct Definition: TokenSequenceGenerator {
  public let list: DefinitonList

  public var tokens: Parenthesized<DefinitonList> {
    return list.parenthesized
  }

  public init(_ list: DefinitonList) {
    self.list = list
  }
}

