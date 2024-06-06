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
