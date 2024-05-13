/* *************************************************************************************************
 ProductionExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A reference to a column.
public struct ColumnReference: ProductionExpression,
                               ValueExpression,
                               QualifiedName,
                               ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public let tableName: TableName?

  public let columnName: String

  /// Additional elements of indirection.
  ///
  /// This property can make an instance compatible with PostgreSQL's parser
  /// because `columnref` is defined as `ColId | ColId indirection` in "gram.y".
  public var trailingIndirection: Indirection? = nil

  public var identifier: ColumnIdentifier {
    return tableName?.identifier ?? ColumnIdentifier(columnName)
  }

  public var indirection: Indirection? {
    guard let tableName else { return nil }
    let colElem = Indirection.List.Element.attributeName(AttributeName(ColumnLabel(columnName)))
    if var indirection = tableName.indirection {
      indirection.list.append(colElem)
      if let trailingIndirection {
        indirection.list.append(contentsOf: trailingIndirection.list)
      }
      return indirection
    } else {
      var list = NonEmptyList<Indirection.List.Element>(item: colElem)
      if let trailingIndirection {
        list.append(contentsOf: trailingIndirection.list)
      }
      return Indirection(Indirection.List(list))
    }
  }

  public init(tableName: TableName? = nil, columnName: String) {
    self.tableName = tableName
    self.columnName = columnName
  }

  public init(stringLiteral value: String) {
    self.init(columnName: value)
  }
}

// MARK: - ConstantExpression

/// A type representing a constant as an expression.
/// It is described as `AexprConst` in "gram.y".
public protocol ConstantExpression: ProductionExpression {}

// MARK: - SingleTokenConstantExpression

/// A type of constant expression that contains only one token.
public protocol SingleTokenConstantExpression: ConstantExpression
where Tokens == Array<Element>,
      Iterator == SingleTokenIterator<Element> {
  var token: Element { get }
  init?(_ token: SQLToken)
}

extension SingleTokenConstantExpression {
  public var tokens: Tokens {
    return [self.token]
  }

  public func makeIterator() -> Iterator {
    return .init(self.token)
  }
}

/// Unsigned integer constant representation, which is described as `Iconst` (`ICONST`) in "gram.y".
public struct UnsignedIntegerConstantExpression: SingleTokenConstantExpression,
                                                 ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = UInt64

  public typealias Element = SQLToken.NumericConstant

  public let token: SQLToken.NumericConstant

  public init?(_ token: SQLToken) {
    guard
      case let numericConstantToken as SQLToken.NumericConstant = token,
      numericConstantToken.isInteger, !numericConstantToken.isNegative
    else {
      return nil
    }
    self.token = numericConstantToken
  }

  public init<T>(_ uint: T) where T: UnsignedInteger & SQLIntegerType {
    self.token = SQLToken.NumericConstant(uint)
  }

  public init(integerLiteral value: UInt64) {
    self.init(value)
  }
}

/// Unsigned float constant representation, which is described as `FCONST` in "gram.y".
public struct UnsignedFloatConstantExpression: SingleTokenConstantExpression,
                                               ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = Double
  public typealias Element = SQLToken.NumericConstant

  public let token: SQLToken.NumericConstant

  public init?(_ token: SQLToken) {
    guard
      case let numericConstantToken as SQLToken.NumericConstant = token,
      numericConstantToken.isFloat, !numericConstantToken.isNegative
    else {
      return nil
    }
    self.token = numericConstantToken
  }

  public init?<T>(_ float: T) where T: SQLFloatType {
    if float < 0 {
      return nil
    }
    self.token = SQLToken.NumericConstant(float)
  }

  public init(floatLiteral value: FloatLiteralType) {
    guard let expression = Self.init(value) else {
      fatalError("Unepxected float value: \(value)")
    }
    self = expression
  }
}

/// String constant representation, which is described as `Sconst` (`SCONST`) in "gram.y".
public struct StringConstantExpression: SingleTokenConstantExpression, ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public typealias Element = SQLToken.StringConstant

  public let token: SQLToken.StringConstant

  public init?(_ token: SQLToken) {
    guard case let strToken as SQLToken.StringConstant = token else { return nil }
    self.token = strToken
  }

  public init<S>(_ string: S, encodingIsUTF8: Bool = true) where S: StringProtocol {
    self.token = SQLToken.StringConstant(rawValue: String(string), encodingIsUTF8: encodingIsUTF8)
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}


/// Bit-string constant representation, which is described as `BCONST` and `XCONST` in "gram.y".
public struct BitStringConstantExpression: SingleTokenConstantExpression {
  public typealias Element = SQLToken.BitStringConstant

  public let token: SQLToken.BitStringConstant
  
  public init?(_ token: SQLToken) {
    guard case let bToken as SQLToken.BitStringConstant = token else { return nil }
    self.token = bToken
  }
}

// MARK: /SingleTokenConstantExpression -

/// Representation of a generic type syntax,  that is described as `func_name Sconst` or
/// `func_name '(' func_arg_list opt_sort_clause ')' Sconst` in "gram.y".
///
/// - Note: While "generic syntax with a type modifier" is defined as
///         `func_name '(' func_arg_list opt_sort_clause ')' Sconst`,
///         named argument or sort clause are not allowed here.
public struct GenericTypeCastStringLiteralSyntax: ConstantExpression {
  /// A name of type.
  ///
  /// - Note: Since defined as `func_name` in "gram.y", its type is `FunctionName` here.
  public let typeName: FunctionName

  public let modifiers: FunctionArgumentList?

  public let string: SQLToken.StringConstant

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(
      typeName,
      modifiers?.parenthesized,
      StringConstantExpression(string)
    )
  }

  public init(
    typeName: FunctionName,
    modifiers: FunctionArgumentList? = nil,
    string: SQLToken.StringConstant
  ) {
    self.typeName = typeName
    self.modifiers = modifiers
    self.string = string
  }

  public init?(
    typeName: FunctionName,
    modifiers: FunctionArgumentList? = nil,
    string: SQLToken
  ) {
    guard case let stringConstantToken as SQLToken.StringConstant = string else {
      return nil
    }
    self.init(typeName: typeName, modifiers: modifiers, string: stringConstantToken)
  }

  public init?(
    typeName: FunctionName,
    modifiers: FunctionArgumentList? = nil,
    string: String
  ) {
    self.init(typeName: typeName, modifiers: modifiers, string: SQLToken.string(string))
  }
}

/// String constant type cast for constants, that is described as `ConstTypename Sconst`.
public struct ConstantTypeCastStringLiteralSyntax<Const>: ConstantExpression
where Const: ConstantTypeName {
  
  public let constantTypeName: Const

  public let string: SQLToken.StringConstant

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(constantTypeName, StringConstantExpression(string)!)
  }

  public init(constantTypeName: Const, string: SQLToken.StringConstant) {
    self.constantTypeName = constantTypeName
    self.string = string
  }

  public init?(constantTypeName: Const, string: SQLToken) {
    guard case let stringConstantToken as SQLToken.StringConstant = string else {
      return nil
    }
    self.init(constantTypeName: constantTypeName, string: stringConstantToken)
  }

  public init?(constantTypeName: Const, string: String) {
    self.init(constantTypeName: constantTypeName, string: SQLToken.string(string))
  }
}

/// Constant `INTERVAL` type cast of 'literal' syntax, that is described as
/// `ConstInterval Sconst opt_interval` or `ConstInterval '(' Iconst ')' Sconst`.
public struct ConstantIntervalTypeCastStringLiteralSyntax: ConstantExpression {
  public typealias Option = IntervalOption

  public let string: SQLToken.StringConstant

  public let option: Option?

  public var tokens: JoinedSQLTokenSequence {
    guard let strExpr = StringConstantExpression(string) else {
      fatalError("Failed to create a string constant expression?!")
    }
    let intervalToken = SingleToken(.interval)

    switch option {
    case .fields(let phrase):
      return JoinedSQLTokenSequence(intervalToken, strExpr, phrase)
    case .precision(let p):
      return JoinedSQLTokenSequence(
        intervalToken.followedBy(parenthesized: SingleToken.integer(p)),
        strExpr
      )
    case nil:
      return JoinedSQLTokenSequence(intervalToken, strExpr)
    }
  }

  public init(string: SQLToken.StringConstant, option: Option? = nil) {
    self.string = string
    self.option = option
  }

  public init?(string: SQLToken, option: Option? = nil) {
    guard case let stringConstantToken as SQLToken.StringConstant = string else {
      return nil
    }
    self.init(string: stringConstantToken, option: option)
  }

  public init?(string: String, option: Option? = nil) {
    self.init(string: SQLToken.string(string), option: option)
  }

  public init(string: SQLToken.StringConstant, fields: IntervalFieldsPhrase) {
    self.string = string
    self.option = .fields(fields)
  }

  public init?(string: SQLToken, fields: IntervalFieldsPhrase) {
    guard case let stringConstantToken as SQLToken.StringConstant = string else {
      return nil
    }
    self.init(string: stringConstantToken, fields: fields)
  }

  public init?(string: String, fields: IntervalFieldsPhrase) {
    self.init(string: SQLToken.string(string), fields: fields)
  }

  public init(string: SQLToken.StringConstant, precision: Int) {
    self.string = string
    self.option = .precision(precision)
  }

  public init?(string: SQLToken, precision: Int) {
    guard case let stringConstantToken as SQLToken.StringConstant = string else {
      return nil
    }
    self.init(string: stringConstantToken, precision: precision)
  }

  public init?(string: String, precision: Int) {
    self.init(string: SQLToken.string(string), precision: precision)
  }
}

/// A boolean constant as an expression: `TRUE` or `FALSE`.
public class BooleanConstantExpression: ConstantExpression {
  public let value: Bool
  public let tokens: Array<SQLToken>

  private init(_ value: Bool) {
    self.value = value
    self.tokens = value ? [.true] : [.false]
  }


  /// `TRUE` as an expression.
  public final class True: BooleanConstantExpression {
    fileprivate init() { super.init(true) }
  }

  /// `FALSE` as an expression.
  public final class False: BooleanConstantExpression {
    fileprivate init() { super.init(false) }
  }

  /// An instance of `TRUE` as an expression.
  public static let `true`: BooleanConstantExpression = True()

  /// An instance of `FALSE` as an expression.
  public static let `false`: BooleanConstantExpression = False()
}

/// `NULL` as an expression.
public final class NullConstantExpression: ConstantExpression {
  public let tokens: Array<SQLToken> = [.null]
  public static let null: NullConstantExpression = .init()
}

// MARK: /ConstantExpression -

/// An expression of positional paramter and its indirection,
///  that is described as `PARAM opt_indirection` in "gram.y".
public struct PositionalParameterExpression: ProductionExpression {
  public let parameter: SQLToken.PositionalParameter

  public let indirection: Indirection?

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(SingleToken(parameter), indirection)
  }

  public init(_ parameter: SQLToken.PositionalParameter, indirection: Indirection? = nil) {
    self.parameter = parameter
    self.indirection = indirection
  }

  public init?(_ token: SQLToken, indirection: Indirection? = nil) {
    guard case let parameterToken as SQLToken.PositionalParameter = token else {
      return nil
    }
    self.parameter = parameterToken
    self.indirection = indirection
  }

  public init(_ position: UInt, indirection: Indirection? = nil) {
    self.parameter = .init(position)
    self.indirection = indirection
  }
}

/// An expression of parenthesized `a_expr` with optional `indirection`.
public struct ParenthesizedGeneralExpressionWithIndirection: ProductionExpression {
  public let expression: any GeneralExpression

  public let indirection: Indirection?

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(
      AnySQLTokenSequence(expression).parenthesized,
      indirection
    )
  }

  public init<Expr>(
    _ expression: Expr,
    indirection: Indirection? = nil
  ) where Expr: GeneralExpression {
    self.expression = expression
    self.indirection = indirection
  }
}

/// `CASE` expression that is described as `case_expr` in "gram.y".
public struct CaseExpression: ProductionExpression {
  /// A `CASE` argument to be compared with each `WHEN` condition.
  public let argument: Optional<any GeneralExpression>

  /// A list of `WHEN ... THEN ...`.
  public let conditionalValues: WhenClauseList

  /// A result in `ELSE ...` clause.
  public let defaultValue: Optional<any GeneralExpression>

  private var _defaultValueTokens: JoinedSQLTokenSequence? {
    guard let defaultValue else { return nil }
    return JoinedSQLTokenSequence([
      SingleToken(.else),
      defaultValue as any SQLTokenSequence
    ])
  }

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting([
      SingleToken(.case), argument,
      conditionalValues,
      _defaultValueTokens,
      SingleToken(.end)
    ] as Array<(any SQLTokenSequence)?>)
  }

  public init(
    argument: Optional<any GeneralExpression> = nil,
    conditionalValues: WhenClauseList,
    defaultValue: Optional<any GeneralExpression> = nil
  ) {
    self.argument = argument
    self.conditionalValues = conditionalValues
    self.defaultValue = defaultValue
  }

  @inlinable
  public init<Condition, Result, each OptionalCondition, each OptionalResult>(
    argument: Optional<any GeneralExpression> = nil,
    _ firstWhenClause: WhenClause<Condition, Result>,
    _ optionalWhenClause: repeat WhenClause<each OptionalCondition, each OptionalResult>,
    `else` defaultValue: Optional<any GeneralExpression> = nil
  ) {
    var list = WhenClauseList(firstWhenClause)
    repeat (list.append(each optionalWhenClause))
    
    self.argument = argument
    self.conditionalValues = list
    self.defaultValue = defaultValue
  }

  @inlinable
  public init<Condition, Result, each OptionalCondition, each OptionalResult>(
    argument: Optional<any GeneralExpression> = nil,
    _ firstWhenClauseSeed: (when: Condition, then: Result),
    _ optionalWhenClauseSeed: repeat (when: each OptionalCondition, then: each OptionalResult),
    `else` defaultValue: Optional<any GeneralExpression> = nil
  ) where Condition: GeneralExpression, Result: GeneralExpression,
          repeat each OptionalCondition: GeneralExpression,
          repeat each OptionalResult: GeneralExpression
  {
    var list = WhenClauseList(
      WhenClause(when: firstWhenClauseSeed.when, then: firstWhenClauseSeed.then)
    )
    repeat (
      list.append(
        WhenClause(
          when: (each optionalWhenClauseSeed).when,
          then: (each optionalWhenClauseSeed).then
        )
      )
    )

    self.argument = argument
    self.conditionalValues = list
    self.defaultValue = defaultValue
  }
}
