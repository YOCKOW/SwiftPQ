/* *************************************************************************************************
 GeneralExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// An expression to override the collation of a general expression.
/// It is described as `a_expr COLLATE any_name` in "gram.y".
///
/// Reference: https://www.postgresql.org/docs/current/sql-expressions.html#SQL-SYNTAX-COLLATE-EXPRS
public struct CollationExpression: GeneralExpression {
  public let expression: any GeneralExpression

  public let collation: CollationName

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([
      expression,
      SingleToken.collate,
      collation,
    ])
  }

  public init(expression: any GeneralExpression, collation: CollationName) {
    self.expression = expression
    self.collation = collation
  }
}

extension GeneralExpression {
  public func collate(_ collation: CollationName) -> CollationExpression {
    return CollationExpression(expression: self, collation: collation)
  }
}

///  An expression of time zone converter
///  that is described as `a_expr AT TIME ZONE a_expr` in "gram.y".
public struct AtTimeZoneOperatorInvocation: GeneralExpression {
  private final class _AtTimeZone: Segment {
    let tokens: Array<Token> = [.at, .time, .zone]
    static let atTimeZone: _AtTimeZone = .init()
  }

  public let time: any GeneralExpression

  public let timeZone: any GeneralExpression

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([time, _AtTimeZone.atTimeZone, timeZone])
  }

  public init(time: any GeneralExpression, timeZone: any GeneralExpression) {
    self.time = time
    self.timeZone = timeZone
  }

  public init(time: any GeneralExpression, timeZone: TimeZone) {
    self.time = time
    self.timeZone = StringConstantExpression(timeZone.identifier)
  }
}

extension GeneralExpression {
  public func atTimeZone(_ timeZone: any GeneralExpression) -> AtTimeZoneOperatorInvocation {
    return AtTimeZoneOperatorInvocation(time: self, timeZone: timeZone)
  }

  public func atTimeZone(_ timeZone: TimeZone) -> AtTimeZoneOperatorInvocation {
    return AtTimeZoneOperatorInvocation(time: self, timeZone: timeZone)
  }
}

/// Representation of `a_expr IS NULL_P` (or `a_expr ISNULL`) in "gram.y".
public struct IsNullExpression: GeneralExpression {
  public let value: any GeneralExpression

  /// Use `ISNULL` keyword instead of `IS NULL` if this is `true`.
  public var useOneKeywordSyntax: Bool = false

  public var tokens: JoinedTokenSequence {
    if useOneKeywordSyntax {
      return JoinedTokenSequence([value, SingleToken.isnull])
    }
    return JoinedTokenSequence([value, SingleToken.is, SingleToken.null])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}

extension GeneralExpression {
  public var isNullExpression: IsNullExpression {
    return .init(value: self)
  }
}


/// Representation of `a_expr IS NOT NULL_P` (or `a_expr NOTNULL`) in "gram.y".
public struct IsNotNullExpression: GeneralExpression {
  public let value: any GeneralExpression

  /// Use `NOTNULL` keyword instead of `IS NOT NULL` if this is `true`.
  public var useOneKeywordSyntax: Bool = false

  private final class _IsNotNull: Segment {
    let tokens: Array<Token> = [.is, .not, .null]
    private init() {}
    static let isNotNull: _IsNotNull = .init()
  }

  public var tokens: JoinedTokenSequence {
    if useOneKeywordSyntax {
      return JoinedTokenSequence([value, SingleToken.notnull])
    }
    return JoinedTokenSequence([value, _IsNotNull.isNotNull])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}

extension GeneralExpression {
  public var isNotNullExpression: IsNotNullExpression {
    return .init(value: self)
  }
}


/// Representation of `a_expr IS TRUE_P` in "gram.y".
public struct IsTrueExpression: GeneralExpression {
  public let value: any GeneralExpression

  private final class _IsTrue: Segment {
    let tokens: Array<Token> = [.is, .true]
    private init() {}
    static let isTrue: _IsTrue = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, _IsTrue.isTrue])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}
extension GeneralExpression {
  public var isTrueExpression: IsTrueExpression {
    return .init(value: self)
  }
}

/// Representation of `a_expr IS NOT TRUE_P` in "gram.y".
public struct IsNotTrueExpression: GeneralExpression {
  public let value: any GeneralExpression

  private final class _IsNotTrue: Segment {
    let tokens: Array<Token> = [.is, .not, .true]
    private init() {}
    static let isNotTrue: _IsNotTrue = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, _IsNotTrue.isNotTrue])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}
extension GeneralExpression {
  public var isNotTrueExpression: IsNotTrueExpression {
    return .init(value: self)
  }
}

/// Representation of `a_expr IS FALSE_P` in "gram.y".
public struct IsFalseExpression: GeneralExpression {
  public let value: any GeneralExpression

  private final class _IsFalse: Segment {
    let tokens: Array<Token> = [.is, .false]
    private init() {}
    static let isFalse: _IsFalse = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, _IsFalse.isFalse])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}
extension GeneralExpression {
  public var isFalseExpression: IsFalseExpression {
    return .init(value: self)
  }
}

/// Representation of `a_expr IS NOT FALSE_P` in "gram.y".
public struct IsNotFalseExpression: GeneralExpression {
  public let value: any GeneralExpression

  private final class _IsNotFalse: Segment {
    let tokens: Array<Token> = [.is, .not, .false]
    private init() {}
    static let isNotFalse: _IsNotFalse = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, _IsNotFalse.isNotFalse])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}
extension GeneralExpression {
  public var isNotFalseExpression: IsNotFalseExpression {
    return .init(value: self)
  }
}

/// Representation of `a_expr IS UNKNOWN` in "gram.y".
public struct IsUnknownExpression: GeneralExpression {
  public let value: any GeneralExpression

  private final class _IsUnknown: Segment {
    let tokens: Array<Token> = [.is, .unknown]
    private init() {}
    static let isUnknown: _IsUnknown = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, _IsUnknown.isUnknown])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}
extension GeneralExpression {
  public var isUnknownExpression: IsUnknownExpression {
    return .init(value: self)
  }
}

/// Representation of `a_expr IS NOT UNKNOWN` in "gram.y".
public struct IsNotUnknownExpression: GeneralExpression {
  public let value: any GeneralExpression

  private final class _IsNotUnknown: Segment {
    let tokens: Array<Token> = [.is, .not, .unknown]
    private init() {}
    static let isNotUnknown: _IsNotUnknown = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, _IsNotUnknown.isNotUnknown])
  }

  public init(value: any GeneralExpression) {
    self.value = value
  }
}
extension GeneralExpression {
  public var isNotUnknownExpression: IsNotUnknownExpression {
    return .init(value: self)
  }
}

/// Representation of `BETWEEN` predicate expression.
public struct BetweenExpression: GeneralExpression {
  public struct Range: TokenSequenceGenerator {
    public var isSymmetric: Bool?

    public let lowerEndpoint: any RestrictedExpression
    public let upperEndpoint: any GeneralExpression

    public var tokens: JoinedTokenSequence {
      var sequences: [any TokenSequenceGenerator] = []
      switch isSymmetric {
      case true:
        sequences.append(SingleToken.symmetric)
      case false:
        sequences.append(SingleToken.asymmetric)
      default:
        break
      }
      sequences.append(
        JoinedTokenSequence([lowerEndpoint, upperEndpoint], separator: SingleToken.and)
      )
      return JoinedTokenSequence(sequences)
    }

    public init(
      isSymmetric: Bool? = nil,
      lower lowerEndpoint: any RestrictedExpression,
      upper upperEndpoint: any GeneralExpression
    ) {
      self.lowerEndpoint = lowerEndpoint
      self.upperEndpoint = upperEndpoint
    }
  }

  public let value: any GeneralExpression

  public var range: Range

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, range], separator: SingleToken.between)
  }

  public init(value: any GeneralExpression, range: Range) {
    self.value = value
    self.range = range
  }

  public init(
    value: any GeneralExpression,
    between lower: any RestrictedExpression,
    and upper: any GeneralExpression
  ) {
    self.value = value
    self.range = Range(lower: lower, upper: upper)
  }
}
extension GeneralExpression {
  /// Creates an expression `self BETWEEN lower AND upper`.
  public func between(
    _ lower: any RestrictedExpression,
    and upper: any GeneralExpression
  ) -> BetweenExpression {
    return .init(value: self, between: lower, and: upper)
  }
}

/// Representation of `NOT BETWEEN` predicate expression.
public struct NotBetweenExpression: GeneralExpression {
  public typealias Range = BetweenExpression.Range

  public let value: any GeneralExpression

  public var range: Range

  private final class _NotBetween: Segment {
    let tokens: Array<Token> = [.not, .between]
    private init() {}
    static let notBetween: _NotBetween = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, range], separator: _NotBetween.notBetween)
  }

  public init(value: any GeneralExpression, range: Range) {
    self.value = value
    self.range = range
  }

  public init(
    value: any GeneralExpression,
    notBetween lower: any RestrictedExpression,
    and upper: any GeneralExpression
  ) {
    self.value = value
    self.range = Range(lower: lower, upper: upper)
  }
}
extension GeneralExpression {
  /// Creates an expression `self NOT BETWEEN lower AND upper`.
  public func notBetween(
    _ lower: any RestrictedExpression,
    and upper: any GeneralExpression
  ) -> NotBetweenExpression {
    return .init(value: self, notBetween: lower, and: upper)
  }
}


/// An expression that is described as `a_expr IN_P in_expr` in "gram.y".
public struct InExpression: GeneralExpression {
  /// Representation of subquery that is described as `in_expr` in "gram.y".
  public struct Subquery: TokenSequence {
    private enum _Generator {
      case parenthesizedSelect(AnyParenthesizedSelectStatement)
      case expressionList(GeneralExpressionList)
    }

    private let _generator: _Generator

    public struct Iterator: IteratorProtocol {
      public typealias Element = Token
      private let _iterator: AnyTokenSequenceIterator
      fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
      public func next() -> Token? { return _iterator.next() }
    }
    public typealias Tokens = Self

    public func makeIterator() -> Iterator {
      switch _generator {
      case .parenthesizedSelect(let select):
        return Iterator(select._asAny.makeIterator())
      case .expressionList(let list):
        return Iterator(list.parenthesized._asAny.makeIterator())
      }
    }

    public init<S>(_ parenthesizedSelectStatement: Parenthesized<S>) where S: SelectStatement {
      self._generator = .parenthesizedSelect(.init(parenthesizedSelectStatement))
    }

    public init<S>(parenthesizing selectStatement: S) where S: SelectStatement {
      self._generator = .parenthesizedSelect(.init(parenthesizing: selectStatement))
    }

    public init(_ expressions: GeneralExpressionList) {
      self._generator = .expressionList(expressions)
    }
  }

  public let value: any GeneralExpression

  public let subquery: Subquery

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, subquery], separator: SingleToken.in)
  }

  public init(_ value: any GeneralExpression, in subquery: Subquery) {
    self.value = value
    self.subquery = subquery
  }

  public init<S>(
    _ value: any GeneralExpression,
    in subquery: Parenthesized<S>
  ) where S: SelectStatement {
    self.value = value
    self.subquery = .init(subquery)
  }

  public init(_ value: any GeneralExpression, in list: GeneralExpressionList) {
    self.value = value
    self.subquery = .init(list)
  }
}
extension GeneralExpression {
  /// Creates a `self IN (subquery)` expression.
  public func `in`(_ subquery: InExpression.Subquery) -> InExpression {
    return .init(self, in: subquery)
  }

  /// Creates a `self IN (subquery)` expression.
  public func `in`<S>(_ subquery: Parenthesized<S>) -> InExpression where S: SelectStatement {
    return .init(self, in: subquery)
  }

  /// Creates a `self IN (subquery)` expression.
  public func `in`<S>(_ subquery: S) -> InExpression where S: SelectStatement {
    return .init(self, in: subquery.parenthesized)
  }


  /// Creates a `self IN (list)` expression.
  public func `in`(_ list: GeneralExpressionList) -> InExpression {
    return .init(self, in: list)
  }
}

/// An expression that is described as `a_expr NOT_LA IN_P in_expr` in "gram.y".
public struct NotInExpression: GeneralExpression {
  public typealias Subquery = InExpression.Subquery

  public let value: any GeneralExpression

  public let subquery: Subquery

  private final class _NotIn: Segment {
    let tokens: Array<Token> = [.not, .in]
    private init() {}
    static let notIn: _NotIn = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([value, subquery], separator: _NotIn.notIn)
  }

  public init(_ value: any GeneralExpression, notIn subquery: Subquery) {
    self.value = value
    self.subquery = subquery
  }

  public init<S>(
    _ value: any GeneralExpression,
    notIn subquery: Parenthesized<S>
  ) where S: SelectStatement {
    self.value = value
    self.subquery = .init(subquery)
  }

  public init(_ value: any GeneralExpression, notIn list: GeneralExpressionList) {
    self.value = value
    self.subquery = .init(list)
  }
}
extension GeneralExpression {
  /// Creates a `self NOT IN (subquery)` expression.
  public func notIn(_ subquery: InExpression.Subquery) -> NotInExpression {
    return .init(self, notIn: subquery)
  }

  /// Creates a `self NOT IN (subquery)` expression.
  public func notIn<S>(_ subquery: Parenthesized<S>) -> NotInExpression where S: SelectStatement {
    return .init(self, notIn: subquery)
  }

  /// Creates a `self NOT IN (subquery)` expression.
  public func notIn<S>(_ subquery: S) -> NotInExpression where S: SelectStatement {
    return .init(self, notIn: subquery.parenthesized)
  }

  /// Creates a `self NOT IN (list)` expression.
  public func notIn(_ list: GeneralExpressionList) -> NotInExpression {
    return .init(self, notIn: list)
  }
}


/// An expression that generates a Boolean result by evaluating left-hand side expression and
/// comparing it to each row of the subquery result or to each element of the array using the given
/// operator.
/// This expression is described as `a_expr subquery_Op sub_type select_with_parens` or
/// `a_expr subquery_Op sub_type '(' a_expr ')'` in "gram.y".
public struct SatisfyExpression: GeneralExpression {
  /// A keyword to determine how to generate the result. It is described as `sub_type` in "gram.y".
  public enum Kind: CustomTokenConvertible {
    case `any`
    case `some`
    case all

    public var token: Token {
      switch self {
      case .any:
        return .any
      case .some:
        return .some
      case .all:
        return .all
      }
    }
  }

  private enum _Elements {
    case subquery(AnyParenthesizedSelectStatement)
    case array(any GeneralExpression)
  }

  public let value: any GeneralExpression

  public let comparator: SubqueryOperator

  public let kind: Kind

  private let _elements: _Elements

  public func subquery<T>(as type: T.Type) -> T? where T: SelectStatement {
    guard case .subquery(let statement) = _elements else {
      return nil
    }
    return statement.subquery(as: T.self)
  }

  public var array: (any GeneralExpression)? {
    guard case .array(let expr) = _elements else {
      return nil
    }
    return expr
  }

  public var tokens: JoinedTokenSequence {
    var sequences: [any TokenSequenceGenerator] = [value, comparator, kind.asSequence]
    switch _elements {
    case .subquery(let parenthesizedSelectStatement):
      sequences.append(parenthesizedSelectStatement)
    case .array(let arrayExpr):
      sequences.append(arrayExpr._asAny.parenthesized)
    }
    return JoinedTokenSequence(sequences)
  }

  public init<S>(
    value: any GeneralExpression,
    comparator: SubqueryOperator,
    kind: Kind,
    subquery: Parenthesized<S>
  ) where S: SelectStatement {
    self.value = value
    self.comparator = comparator
    self.kind = kind
    self._elements = .subquery(.init(subquery))
  }

  public init<S>(
    value: any GeneralExpression,
    comparator: SubqueryOperator,
    kind: Kind,
    subquery: S
  ) where S: SelectStatement {
    self.value = value
    self.comparator = comparator
    self.kind = kind
    self._elements = .subquery(.init(parenthesizing: subquery))
  }

  public init(
    value: any GeneralExpression,
    comparator: SubqueryOperator,
    kind: Kind,
    array: any GeneralExpression
  )  {
    self.value = value
    self.comparator = comparator
    self.kind = kind
    self._elements = .array(array)
  }

  public init(
    value: any GeneralExpression,
    comparator: SubqueryOperator,
    kind: Kind,
    array: ArrayConstructorExpression
  ) {
    self.value = value
    self.comparator = comparator
    self.kind = kind
    self._elements = .array(array)
  }

  public init(
    value: any GeneralExpression,
    comparator: SubqueryOperator,
    kind: Kind,
    elements: GeneralExpressionList
  ) {
    self.value = value
    self.comparator = comparator
    self.kind = kind
    self._elements = .array(ArrayConstructorExpression(elements))
  }
}


/// Representation of `UNIQUE` predicate expression that is described as
/// `UNIQUE opt_unique_null_treatment select_with_parens` in "gram.y".
///
/// - Warning: This expression is not implemented in PostgreSQL as of version 16.
public struct UniquePredicateExpression: GeneralExpression {
  public let nullTreatment: NullTreatment?
  
  private let _subquery: AnyParenthesizedSelectStatement

  public func subquery<T>(as type: T.Type) -> T? where T: SelectStatement {
    return _subquery.subquery(as: T.self)
  }

  public var tokens: JoinedTokenSequence {
    return .compacting(SingleToken.unique, nullTreatment, _subquery)
  }

  public init<S>(
    nullTreatment: NullTreatment? = nil,
    subquery: Parenthesized<S>
  ) where S: SelectStatement {
    self.nullTreatment = nullTreatment
    self._subquery = AnyParenthesizedSelectStatement(subquery)
  }


  public init<S>(
    nullTreatment: NullTreatment? = nil,
    parenthesizing subquery: S
  ) where S: SelectStatement {
    self.nullTreatment = nullTreatment
    self._subquery = AnyParenthesizedSelectStatement(parenthesizing: subquery)
  }
}


/// Representation of `IS [form] NORMALIZED` expression that is described as
/// `a_expr IS NORMALIZED` or `a_expr IS unicode_normal_form NORMALIZED` in "gram.y".
public struct IsNormalizedExpression: GeneralExpression {
  public let text: any GeneralExpression

  public let form: UnicodeNormalizationForm?

  public var tokens: JoinedTokenSequence {
    return .compacting([text, SingleToken.is, form?.asSequence, SingleToken.normalized])
  }

  public init(text: any GeneralExpression, form: UnicodeNormalizationForm? = nil) {
    self.text = text
    self.form = form
  }
}
extension GeneralExpression {
  public func isNormalizedExpression(form: UnicodeNormalizationForm? = nil) -> IsNormalizedExpression {
    return .init(text: self, form:form)
  }

  public var isNormalizedExpression: IsNormalizedExpression {
    return .init(text: self, form: nil)
  }
}

/// Representation of `IS Not [form] NORMALIZED` expression that is described as
/// `a_expr IS NOT NORMALIZED` or `a_expr IS NOT unicode_normal_form NORMALIZED` in "gram.y".
public struct IsNotNormalizedExpression: GeneralExpression {
  public let text: any GeneralExpression

  public let form: UnicodeNormalizationForm?

  public var tokens: JoinedTokenSequence {
    return .compacting([text, SingleToken.is, SingleToken.not, form?.asSequence, SingleToken.normalized])
  }

  public init(text: any GeneralExpression, form: UnicodeNormalizationForm? = nil) {
    self.text = text
    self.form = form
  }
}
extension GeneralExpression {
  public func isNotNormalizedExpression(form: UnicodeNormalizationForm? = nil) -> IsNotNormalizedExpression {
    return .init(text: self, form:form)
  }

  public var isNotNormalizedExpression: IsNotNormalizedExpression {
    return .init(text: self, form: nil)
  }
}


/// Representation of `a_expr IS json_predicate_type_constraint json_key_uniqueness_constraint_opt`
/// expression.
public struct IsJSONTypeExpression: GeneralExpression {
  public let value: any GeneralExpression

  public let type: JSONPredicateType

  public let keyUniquenessOption: JSONKeyUniquenessOption?

  public var tokens: JoinedTokenSequence {
    return .compacting([value, SingleToken.is, type, keyUniquenessOption])
  }

  public init(
    value: any GeneralExpression,
    type: JSONPredicateType,
    keyUniquenessOption: JSONKeyUniquenessOption? = nil
  ) {
    self.value = value
    self.type = type
    self.keyUniquenessOption = keyUniquenessOption
  }
}


/// Representation of `a_expr IS NOT json_predicate_type_constraint json_key_uniqueness_constraint_opt`
/// expression.
public struct IsNotJSONTypeExpression: GeneralExpression {
  public let value: any GeneralExpression

  public let type: JSONPredicateType

  public let keyUniquenessOption: JSONKeyUniquenessOption?

  public var tokens: JoinedTokenSequence {
    return .compacting([value, SingleToken.is, SingleToken.not, type, keyUniquenessOption])
  }

  public init(
    value: any GeneralExpression,
    type: JSONPredicateType,
    keyUniquenessOption: JSONKeyUniquenessOption? = nil
  ) {
    self.value = value
    self.type = type
    self.keyUniquenessOption = keyUniquenessOption
  }
}


/// `DEFAULT` as an expression.
public final class DefaultExpression: GeneralExpression {
  public let tokens: Array<Token> = [.default]
  private init() {}
  public static let `default`: DefaultExpression = .init()
}
