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

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence([
      expression,
      SingleToken(.collate),
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
    let tokens: Array<SQLToken> = [.at, .time, .zone]
    static let atTimeZone: _AtTimeZone = .init()
  }

  public let time: any GeneralExpression

  public let timeZone: any GeneralExpression

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence([time, _AtTimeZone.atTimeZone, timeZone])
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

  public var tokens: JoinedSQLTokenSequence {
    if useOneKeywordSyntax {
      return JoinedSQLTokenSequence([value, SingleToken(.isnull)])
    }
    return JoinedSQLTokenSequence([value, SingleToken(.is), SingleToken(.null)])
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
    let tokens: Array<SQLToken> = [.is, .not, .null]
    private init() {}
    static let isNotNull: _IsNotNull = .init()
  }

  public var tokens: JoinedSQLTokenSequence {
    if useOneKeywordSyntax {
      return JoinedSQLTokenSequence([value, SingleToken(.notnull)])
    }
    return JoinedSQLTokenSequence([value, _IsNotNull.isNotNull])
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
