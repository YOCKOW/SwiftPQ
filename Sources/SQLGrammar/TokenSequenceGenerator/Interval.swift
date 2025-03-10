/* *************************************************************************************************
 Interval.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A phrase to restrict the set of stored fields of an interval type.
///
/// See `opt_interval` and `interval_second` in "gram.y".
public enum IntervalFieldsPhrase: Segment {
  case year
  case month
  case day
  case hour
  case minute
  case second(precision: UnsignedIntegerConstantExpression? = nil)
  public static let second: IntervalFieldsPhrase = .second()
  case yearToMonth
  case dayToHour
  case dayToMinute
  case dayToSecond(precision: UnsignedIntegerConstantExpression? = nil)
  public static let dayToSecond: IntervalFieldsPhrase = .dayToSecond()
  case hourToMinute
  case hourToSecond(precision: UnsignedIntegerConstantExpression? = nil)
  public static let hourToSecond: IntervalFieldsPhrase = .hourToSecond()
  case minuteToSecond(precision: UnsignedIntegerConstantExpression? = nil)
  public static let minuteToSecond: IntervalFieldsPhrase = .minuteToSecond()

  public var tokens: JoinedTokenSequence {
    var tokens: [Token] = []
    var precision: UnsignedIntegerConstantExpression? = nil

    switch self {
    case .year:
      tokens.append(.year)
    case .month:
      tokens.append(.month)
    case .day:
      tokens.append(.day)
    case .hour:
      tokens.append(.hour)
    case .minute:
      tokens.append(.minute)
    case .second(let p):
      tokens.append(.second)
      precision = p
    case .yearToMonth:
      tokens.append(contentsOf: [.year, .to, .month])
    case .dayToHour:
      tokens.append(contentsOf: [.day, .to, .hour])
    case .dayToMinute:
      tokens.append(contentsOf: [.day, .to, .minute])
    case .dayToSecond(let p):
      tokens.append(contentsOf: [.day, .to, .second])
      precision = p
    case .hourToMinute:
      tokens.append(contentsOf: [.hour, .to, .minute])
    case .hourToSecond(let p):
      tokens.append(contentsOf: [.hour, .to, .second])
      precision = p
    case .minuteToSecond(let p):
      tokens.append(contentsOf: [.minute, .to, .second])
      precision = p
    }

    let tokensSeq = UnknownSQLTokenSequence(tokens)
    if let precision {
      return tokensSeq.followedBy(parenthesized: precision)
    } else {
      return JoinedTokenSequence(tokensSeq)
    }
  }
}

/// An option for `INTERVAL`'s `opt_interval` or `'(' Iconst ')'`
public enum IntervalOption: Sendable {
  case fields(IntervalFieldsPhrase)
  case precision(UnsignedIntegerConstantExpression)
}
