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

  public let identifier: ColumnIdentifier

  public let indirection: Indirection?

  public init(identifier: ColumnIdentifier, indirection: Indirection? = nil) {
    self.identifier = identifier
    self.indirection = indirection
  }

  public init(stringLiteral value: String) {
    self.init(identifier: ColumnIdentifier(stringLiteral: value), indirection: nil)
  }

  @inlinable
  public init(tableName: TableName? = nil, columnName: String) {
    if let tableName {
      let columnNameIndirectionElement: Indirection.List.Element =
        .attributeName(AttributeName(ColumnLabel(columnName)))
      if var indirection = tableName.indirection {
        indirection.list.append(columnNameIndirectionElement)
        self.init(identifier: tableName.identifier, indirection: indirection)
      } else {
        self.init(
          identifier: tableName.identifier,
          indirection: [columnNameIndirectionElement]
        )
      }
    } else {
      self.init(identifier: ColumnIdentifier(columnName))
    }
  }

  internal var asAnyName: (some AnyName)? {
    return AnyAnyName(qualifiedName: self)
  }
}

// MARK: - ConstantExpression

/// A type representing a constant as an expression.
/// It is described as `AexprConst` in "gram.y".
public protocol ConstantExpression: ProductionExpression {}

// MARK: - SingleTokenConstantExpression

/// A type of constant expression that contains only one token.
public protocol SingleTokenConstantExpression: ConstantExpression 
  where Self.Tokens == Array<Self.ConstantToken>
{
  /// A token that represents the constant value.
  associatedtype ConstantToken: Token

  var token: ConstantToken { get }
  init?(_ token: Token)
}

extension SingleTokenConstantExpression {
  @inlinable
  public var tokens: Array<ConstantToken> {
    return [self.token]
  }
}

/// Unsigned integer constant representation, which is described as `Iconst` (`ICONST`) in "gram.y".
public struct UnsignedIntegerConstantExpression: SingleTokenConstantExpression,
                                                 ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = UInt64

  public typealias ConstantToken = Token.NumericConstant

  public let token: Token.NumericConstant

  public init?(_ token: Token) {
    guard
      case let numericConstantToken as Token.NumericConstant = token,
      numericConstantToken.isInteger
    else {
      return nil
    }
    self.token = numericConstantToken
  }

  public init<T>(_ uint: T) where T: SQLIntegerType {
    self.token = Token.NumericConstant.Integer<T>(uint)
  }

  public init(integerLiteral value: UInt64) {
    self.init(value)
  }
}

/// Unsigned float constant representation, which is described as `FCONST` in "gram.y".
public struct UnsignedFloatConstantExpression: SingleTokenConstantExpression,
                                               ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = Double
  public typealias ConstantToken = Token.NumericConstant

  public let token: Token.NumericConstant

  public init?(_ token: Token) {
    guard
      case let numericConstantToken as Token.NumericConstant = token,
      numericConstantToken.isFloat
    else {
      return nil
    }
    self.token = numericConstantToken
  }

  public init?<T>(_ float: T) where T: SQLFloatType {
    if float < 0 {
      return nil
    }
    self.token = Token.NumericConstant.Float<T>(float)
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
  public typealias ConstantToken = Token.StringConstant

  public let token: Token.StringConstant

  public init?(_ token: Token) {
    guard case let strToken as Token.StringConstant = token else { return nil }
    self.token = strToken
  }

  public init<S>(_ string: S, encodingIsUTF8: Bool = true) where S: StringProtocol {
    self.token = Token.StringConstant(rawValue: String(string), encodingIsUTF8: encodingIsUTF8)
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}


/// Bit-string constant representation, which is described as `BCONST` and `XCONST` in "gram.y".
public struct BitStringConstantExpression: SingleTokenConstantExpression {
  public typealias ConstantToken = Token.BitStringConstant

  public let token: Token.BitStringConstant
  
  public init?(_ token: Token) {
    guard case let bToken as Token.BitStringConstant = token else { return nil }
    self.token = bToken
  }
}

// MARK: /SingleTokenConstantExpression -

internal protocol _PossiblyFunctionNameWithModifiersConvertible {
  var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? { get }
}

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

  public let string: Token.StringConstant

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence.compacting(
      typeName,
      modifiers?.parenthesized,
      StringConstantExpression(string)
    )
  }

  public init(
    typeName: FunctionName,
    modifiers: FunctionArgumentList? = nil,
    string: Token.StringConstant
  ) {
    self.typeName = typeName
    self.modifiers = modifiers
    self.string = string
  }

  public init?(
    typeName: FunctionName,
    modifiers: FunctionArgumentList? = nil,
    string: Token
  ) {
    guard case let stringConstantToken as Token.StringConstant = string else {
      return nil
    }
    self.init(typeName: typeName, modifiers: modifiers, string: stringConstantToken)
  }

  public init?(
    typeName: FunctionName,
    modifiers: FunctionArgumentList? = nil,
    string: String
  ) {
    self.init(typeName: typeName, modifiers: modifiers, string: Token.string(string))
  }

  public init?(typeName: TypeName, string: String) {
    guard let functionNameWithModifiers = typeName._functionNameWithModifiers else {
      return nil
    }
    self.init(
      typeName: functionNameWithModifiers.0,
      modifiers: functionNameWithModifiers.1,
      string: string
    )
  }

  public init?<Name>(typeName: Name, string: String) where Name: SimpleTypeName {
    self.init(typeName: typeName.typeName, string: string)
  }
}

/// String constant type cast for constants, that is described as `ConstTypename Sconst`.
public struct ConstantTypeCastStringLiteralSyntax<Const>: ConstantExpression
where Const: ConstantTypeName {
  
  public let constantTypeName: Const

  public let string: Token.StringConstant

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(constantTypeName, StringConstantExpression(string)!)
  }

  public init(constantTypeName: Const, string: Token.StringConstant) {
    self.constantTypeName = constantTypeName
    self.string = string
  }

  public init?(constantTypeName: Const, string: Token) {
    guard case let stringConstantToken as Token.StringConstant = string else {
      return nil
    }
    self.init(constantTypeName: constantTypeName, string: stringConstantToken)
  }

  public init(constantTypeName: Const, string: String) {
    self.init(constantTypeName: constantTypeName, string: Token.string(string))!
  }
}

/// Constant `INTERVAL` type cast of 'literal' syntax, that is described as
/// `ConstInterval Sconst opt_interval` or `ConstInterval '(' Iconst ')' Sconst`.
public struct ConstantIntervalTypeCastStringLiteralSyntax: ConstantExpression {
  public typealias Option = IntervalOption

  public let string: Token.StringConstant

  public let option: Option?

  public var tokens: JoinedTokenSequence {
    guard let strExpr = StringConstantExpression(string) else {
      fatalError("Failed to create a string constant expression?!")
    }
    let intervalToken = SingleToken.interval

    switch option {
    case .fields(let phrase):
      return JoinedTokenSequence(intervalToken, strExpr, phrase)
    case .precision(let p):
      return JoinedTokenSequence(
        intervalToken.followedBy(parenthesized: p),
        strExpr
      )
    case nil:
      return JoinedTokenSequence(intervalToken, strExpr)
    }
  }

  public init(string: Token.StringConstant, option: Option? = nil) {
    self.string = string
    self.option = option
  }

  public init?(string: Token, option: Option? = nil) {
    guard case let stringConstantToken as Token.StringConstant = string else {
      return nil
    }
    self.init(string: stringConstantToken, option: option)
  }

  public init?(string: String, option: Option? = nil) {
    self.init(string: Token.string(string), option: option)
  }

  public init(string: Token.StringConstant, fields: IntervalFieldsPhrase) {
    self.string = string
    self.option = .fields(fields)
  }

  public init?(string: Token, fields: IntervalFieldsPhrase) {
    guard case let stringConstantToken as Token.StringConstant = string else {
      return nil
    }
    self.init(string: stringConstantToken, fields: fields)
  }

  public init?(string: String, fields: IntervalFieldsPhrase) {
    self.init(string: Token.string(string), fields: fields)
  }

  public init(string: Token.StringConstant, precision: UnsignedIntegerConstantExpression) {
    self.string = string
    self.option = .precision(precision)
  }

  public init?(string: Token, precision: UnsignedIntegerConstantExpression) {
    guard case let stringConstantToken as Token.StringConstant = string else {
      return nil
    }
    self.init(string: stringConstantToken, precision: precision)
  }

  public init?(string: String, precision: UnsignedIntegerConstantExpression) {
    self.init(string: Token.string(string), precision: precision)
  }
}

/// A boolean constant as an expression: `TRUE` or `FALSE`.
public class BooleanConstantExpression: ConstantExpression, @unchecked Sendable {
  public let value: Bool
  public let tokens: Array<Token>

  private init(_ value: Bool) {
    self.value = value
    self.tokens = value ? [.true] : [.false]
  }


  /// `TRUE` as an expression.
  public final class True: BooleanConstantExpression, @unchecked Sendable {
    fileprivate init() { super.init(true) }
  }

  /// `FALSE` as an expression.
  public final class False: BooleanConstantExpression, @unchecked Sendable {
    fileprivate init() { super.init(false) }
  }

  /// An instance of `TRUE` as an expression.
  public static let `true`: BooleanConstantExpression = True()

  /// An instance of `FALSE` as an expression.
  public static let `false`: BooleanConstantExpression = False()
}

/// `NULL` as an expression.
public final class NullConstantExpression: ConstantExpression {
  public let tokens: Array<Token> = [.null]
  public static let null: NullConstantExpression = .init()
}

// MARK: /ConstantExpression -

/// An expression of positional paramter and its indirection,
///  that is described as `PARAM opt_indirection` in "gram.y".
public struct PositionalParameterExpression: ProductionExpression {
  public let parameter: Token.PositionalParameter

  public let indirection: Indirection?

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence.compacting(SingleToken(parameter), indirection)
  }

  public init(_ parameter: Token.PositionalParameter, indirection: Indirection? = nil) {
    self.parameter = parameter
    self.indirection = indirection
  }

  public init?(_ token: Token, indirection: Indirection? = nil) {
    guard case let parameterToken as Token.PositionalParameter = token else {
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

extension Token.PositionalParameter {
  @inlinable
  public var asExpression: PositionalParameterExpression {
    return .init(self)
  }
}

/// An expression of parenthesized `a_expr` with optional `indirection`.
public struct ParenthesizedGeneralExpressionWithIndirection: ProductionExpression {
  public let expression: any GeneralExpression 

  public let indirection: Indirection?

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence.compacting(
      AnyTokenSequenceGenerator(expression).parenthesized,
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

  private var _defaultValueTokens: JoinedTokenSequence? {
    guard let defaultValue else { return nil }
    return JoinedTokenSequence([
      SingleToken.else,
      defaultValue as any TokenSequenceGenerator
    ])
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence.compacting([
      SingleToken.case, argument,
      conditionalValues,
      _defaultValueTokens,
      SingleToken.end
    ] as Array<(any TokenSequenceGenerator)?>)
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

/// Representation of `SELECT` as an expression.
///
/// - Note: Described as one of `c_expr`s:
///         `select_with_parens` or `select_with_parens indirection` in "gram.y".
public struct SelectExpression: ProductionExpression  {
  private let _subquery: AnyParenthesizedSelectStatement

  public func subquery<Subquery>(as type: Subquery.Type) -> Subquery? where Subquery: SelectStatement {
    return _subquery.subquery(as: Subquery.self)
  }

  public let indirection: Indirection?

  public var tokens: JoinedTokenSequence {
    return .compacting(_subquery, indirection)
  }

  public init<Subquery>(
    _ parenthesizedSubquery: Parenthesized<Subquery>,
    indirection: Indirection? = nil
  ) where Subquery: SelectStatement {
    self._subquery = AnyParenthesizedSelectStatement(parenthesizedSubquery)
    self.indirection = indirection
  }

  public init<Subquery>(
    parenthesizing subquery: Subquery,
    indirection: Indirection? = nil
  ) where Subquery: SelectStatement {
    self._subquery = AnyParenthesizedSelectStatement(parenthesizing: subquery)
    self.indirection = indirection
  }
}

/// An expression described as `EXISTS select_with_parens` in "gram.y".
public struct ExistsExpression: ProductionExpression {
  private let _subquery: AnyParenthesizedSelectStatement

  public func subquery<Subquery>(as type: Subquery.Type) -> Subquery? where Subquery: SelectStatement {
    return _subquery.subquery(as: Subquery.self)
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(SingleToken.exists, _subquery)
  }

  public init<Subquery>(_ parenthesizedSubquery: Parenthesized<Subquery>) where Subquery: SelectStatement {
    self._subquery = AnyParenthesizedSelectStatement(parenthesizedSubquery)
  }

  public init<Subquery>(parenthesizing subquery: Subquery) where Subquery: SelectStatement {
    self._subquery = AnyParenthesizedSelectStatement(parenthesizing: subquery)
  }
}

/// An expression described as `ARRAY select_with_parens` or `ARRAY array_expr` in "gram.y".
public struct ArrayConstructorExpression: ProductionExpression, ValueExpression {
  /// Representation of `array_expr` in "gram.y".
  public struct Subscript: TokenSequenceGenerator {
    /// A list of `Subscript`(`array_expr`) that is described as `array_expr_list` in "gram.y".
    public struct List: TokenSequenceGenerator, InitializableWithNonEmptyList, ExpressibleByArrayLiteral {
      public typealias NonEmptyListElement = Subscript
      public typealias ArrayLiteralElement = Subscript

      public let subscripts: NonEmptyList<Subscript>

      public var tokens: JoinedTokenSequence {
        return subscripts.joinedByCommas()
      }

      public init(_ subscripts: NonEmptyList<Subscript>) {
        self.subscripts = subscripts
      }
    }

    private enum _Values {
      case expressionList(GeneralExpressionList)
      case subscriptList(List)
      case empty
    }

    private let _values: _Values

    public var tokens: JoinedTokenSequence {
      return .compacting(
        LeftSquareBracket.leftSquareBracket,
        ({ (values: _Values) -> JoinedTokenSequence? in
          switch values {
          case .expressionList(let generalExpressionList):
            return generalExpressionList.tokens
          case .subscriptList(let subscriptList):
            return subscriptList.tokens
          case .empty:
            return nil
          }
        })(_values),
        RightSquareBracket.rightSquareBracket
      )
    }

    public init(_ list: GeneralExpressionList) {
      self._values = .expressionList(list)
    }

    public init(_ expr: any GeneralExpression) {
      self._values = .expressionList([expr])
    }

    public init(_ list: List) {
      self._values = .subscriptList(list)
    }

    public init(_ `subscript`: Subscript) {
      self._values = .subscriptList([`subscript`])
    }

    public init() {
      self._values = .empty
    }

    public static let empty: Subscript = .init()
  }

  private enum _Elements {
    case select(AnyParenthesizedSelectStatement)
    case `subscript`(Subscript)
  }

  private let _elements: _Elements

  public func subquery<Select>(as type: Select.Type) -> Select? where Select: SelectStatement {
    guard case .select(let parenthesizedSelectStatement) = _elements else {
      return nil
    }
    return parenthesizedSelectStatement.subquery(as: Select.self)
  }

  public var `subscript`: Subscript? {
    guard case .subscript(let `subscript`) = _elements else {
      return nil
    }
    return `subscript`
  }

  public var tokens: JoinedTokenSequence {
    switch _elements {
    case .select(let parenthesizedSelectStatement):
      return JoinedTokenSequence(
        SingleToken.array,
        SingleToken.joiner,
        parenthesizedSelectStatement
      )
    case .subscript(let `subscript`):
      return JoinedTokenSequence(SingleToken.array, SingleToken.joiner, `subscript`)
    }
  }

  public init<Select>(_ parenthesizedSelect: Parenthesized<Select>) where Select: SelectStatement {
    self._elements = .select(AnyParenthesizedSelectStatement(parenthesizedSelect))
  }

  public init<Select>(parenthesizing select: Select) where Select: SelectStatement {
    self._elements = .select(AnyParenthesizedSelectStatement(parenthesizing: select))
  }

  public init(_ `subscript`: Subscript) {
    self._elements = .subscript(`subscript`)
  }

  @inlinable
  public init(_ expressions: GeneralExpressionList) {
    self.init(Subscript(expressions))
  }

  @inlinable
  public init(_ list: Subscript.List) {
    self.init(Subscript(list))
  }
}

/// A constructor of ROW that is described as `explicit_row`.
public struct RowConstructorExpression: ProductionExpression, ValueExpression {
  public let fields: GeneralExpressionList?

  public var tokens: JoinedTokenSequence {
    if let fields = self.fields {
      return SingleToken.row.followedBy(parenthesized: fields)
    }
    return JoinedTokenSequence(
      SingleToken.row,
      SingleToken.joiner,
      LeftParenthesis.leftParenthesis,
      RightParenthesis.rightParenthesis
    )
  }

  public init(fields: GeneralExpressionList?) {
    self.fields = fields
  }

  public init() {
    self.fields = nil
  }

  public static let empty: RowConstructorExpression = .init()
}

/// A constructor of ROW that is described as `implicit_row` in "gram.y".
public struct ImplicitRowConstructorExpression: ProductionExpression {
  /// Field values of the row.
  ///
  /// - Note: The number of values must be 2 or more
  ///         because `implicit_row` is defined by `'(' expr_list ',' a_expr ')'`
  public let fields: GeneralExpressionList

  @inlinable
  public var lastField: any GeneralExpression {
    return fields.expressions.last
  }

  public var tokens: Parenthesized<GeneralExpressionList> {
    assert(fields.expressions.count >= 2, "Unexpected number of fields?!")
    return fields.parenthesized
  }

  public init(prefixFields: GeneralExpressionList, lastField: any GeneralExpression) {
    var fields = prefixFields
    fields.expressions.append(lastField)
    self.fields = fields
  }

  @inlinable
  public init<FirstField, SecondField, each OptionalField>(
    _ firstField: FirstField,
    _ secondField: SecondField,
    _ optionalField: repeat each OptionalField
  ) where FirstField: GeneralExpression,
          SecondField: GeneralExpression,
          repeat each OptionalField: GeneralExpression
  {
    var fieldExpressions = NonEmptyList<any GeneralExpression>(item: firstField)
    fieldExpressions.append(secondField)
    repeat fieldExpressions.append(each optionalField)
    self.fields = GeneralExpressionList(fieldExpressions)
  }
}


/// Representation of `GROUPING '(' expr_list ')'` in "gram.y".
public struct GroupingExpression: ProductionExpression {
  public let groups: GeneralExpressionList

  public var tokens: JoinedTokenSequence {
    return SingleToken.grouping.followedBy(parenthesized: groups)
  }

  public init(_ groups: GeneralExpressionList) {
    self.groups = groups
  }
}
