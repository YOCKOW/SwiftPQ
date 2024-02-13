/* *************************************************************************************************
 DataType.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of a data type.
public struct DataType {
  public enum InitializationError: Error {
    case emptyTokens
    case invalidValue
  }

  public let tokens: [SQLToken]

  fileprivate init(_tokens: [SQLToken]) {
    self.tokens = _tokens
  }

  fileprivate init(_token: SQLToken) {
    self.init(_tokens: [_token])
  }

  public init(_ tokens: [SQLToken]) throws {
    guard !tokens.isEmpty else { throw InitializationError.emptyTokens }
    self.init(_tokens: tokens)
  }
}

public enum TimeIntervalFields {
  case year
  case month
  case day
  case hour
  case minute
  case second
  case yearToMonth
  case dayToHour
  case dayToMinute
  case dayToSecond
  case hourToMinute
  case hourToSecond
  case minuteToSecond

  fileprivate var tokens: [SQLToken] {
    switch self {
    case .year:
      return [.year]
    case .month:
      return [.month]
    case .day:
      return [.day]
    case .hour:
      return [.hour]
    case .minute:
      return [.minute]
    case .second:
      return [.second]
    case .yearToMonth:
      return [.year, .to, .month]
    case .dayToHour:
      return [.day, .to, .hour]
    case .dayToMinute:
      return [.day, .to, .minute]
    case .dayToSecond:
      return [.day, .to, .second]
    case .hourToMinute:
      return [.hour, .to, .minute]
    case .hourToSecond:
      return [.hour, .to, .second]
    case .minuteToSecond:
      return [.minute, .to, .second]
    }
  }

  fileprivate var precisionAvailable: Bool {
    switch self {
    case .second, .dayToSecond, .hourToSecond, .minuteToSecond:
      return true
    default:
      return false
    }
  }
}

extension DataType {
  /// Signed eight-byte integer
  public static let bigInt: DataType = .init(_token: .bigint)
  public static let int8: DataType = bigInt

  /// Autoincrementing eight-byte integer
  public static let bigSerial: DataType = .init(_tokens: [SQLToken.Keyword(rawValue: "BIGSERIAL")])
  public static let serial8: DataType = bigSerial

  private static func _appendParenthesizedInteger(base: DataType, number: Int) throws -> DataType {
    if number < 1 {
      throw InitializationError.invalidValue
    }
    return .init(
      _tokens: base.tokens + [.joiner, .leftParenthesis, .joiner, .numeric(number), .joiner, .rightParenthesis]
    )
  }

  private static let _bit: DataType = .init(_token: .bit)

  /// Fixed-length bit string
  /// - Parameters:
  ///   - n: The number of the bits.
  public static func bit(_ n: Int? = nil) throws -> DataType {
    guard let n else { return _bit }
    return try _appendParenthesizedInteger(base: ._bit, number: n)
  }

  public static let _varbit: DataType = .init(_tokens: [.bit, .varying])

  /// Variable-length bit string
  /// - Parameters:
  ///   - n: The number of the bits.
  public static func bitVarying(_ n: Int? = nil) throws -> DataType {
    guard let n else { return _varbit }
    return try _appendParenthesizedInteger(base: _varbit, number: n)
  }

  public static let boolean: DataType = .init(_token: .boolean)

  /// Rectangular box on a plane
  public static let box: DataType = .init(_token: .box)

  /// Binary data
  public static let byteArray: DataType = .init(_token: .bytea)


  private static let _character: DataType = .init(_token: .character)

  /// Fixed-length character string.
  /// - Parameters:
  ///   - n: The number of the characters.
  public static func character(_ n: Int? = nil) throws -> DataType {
    guard let n else { return _character }
    return try _appendParenthesizedInteger(base: _character, number: n)
  }

  private static let _varchar: DataType = .init(_tokens: [.character, .varying])

  /// Variable-length character string.
  /// - Parameters:
  ///   - n: The number of the characters.
  public static func characterVarying(_ n: Int? = nil) throws -> DataType {
    guard let n else { return _varchar }
    return try _appendParenthesizedInteger(base: _varchar, number: n)
  }

  /// CIDR
  public static let cidr: DataType = .init(_token: .cidr)

  /// Circle on a plane
  public static let circle: DataType = .init(_token: .circle)

  /// Calendar date
  public static let date: DataType = .init(_token: .date)

  /// Double precision floating-point number
  public static let doublePrecision: DataType = .init(_tokens: [.double, .precision])

  public static let float8: DataType = doublePrecision

  /// IPv4 or IPv6 host address
  public static let inet: DataType = .init(_token: .inet)

  /// Signed four-byte integer
  public static let integer: DataType = .init(_token: .integer)
  public static let int4: DataType = integer


  private static func _appendParenthesizedPrecision(base: inout [SQLToken], precision: Int) throws {
    guard (0...6).contains(precision) else {
      throw InitializationError.invalidValue
    }
    base = base + [.joiner, .leftParenthesis, .joiner, .numeric(precision), .joiner, .rightParenthesis]
  }

  /// Time span
  public static func interval(
    fields: TimeIntervalFields? = nil,
    precision: Int? = nil
  ) throws -> DataType {
    var tokens: [SQLToken] = [.interval]
    fields.map({ tokens.append(contentsOf: $0.tokens) })
    if let precision {
      try _appendParenthesizedPrecision(base: &tokens, precision: precision)
    }
    return .init(_tokens: tokens)
  }

  /// Textual JSON data
  public static let json: DataType = .init(_token: .json)

  /// Binary JSON data
  public static let jsonb: DataType = .init(_token: .jsonb)

  /// Infinite line on a plane
  public static let line: DataType = .init(_token: .line)

  /// Line segment on a plane
  public static let lineSegment: DataType = .init(_token: .lseg)

  /// MAC address.
  public static let macAddress: DataType = .init(_token: .macaddr)

  /// MAC address (EUI-64 format).
  public static let macAddress8: DataType = .init(_token: .macaddr8)

  /// Currency amount
  public static let money: DataType = .init(_token: .money)

  /// Exact numeric of selectable precision
  public static func numeric(precision: Int? = nil, scale: Int? = nil) throws -> DataType {
    var tokens: [SQLToken] = [.numeric]
    switch (precision, scale) {
    case (let p?, let s?):
      tokens.append(contentsOf: [
        .joiner, .leftParenthesis, .joiner,
        .numeric(p), .joiner, .comma, .numeric(s),
        .joiner, .rightParenthesis,
      ])
    case (let p?, nil):
      tokens.append(contentsOf: [
        .joiner, .leftParenthesis, .joiner, .numeric(p), .joiner, .rightParenthesis,
      ])
    case (nil, _?):
      throw InitializationError.invalidValue
    case (nil, nil):
      break
    }
    return .init(_tokens: tokens)
  }

  /// Geometric path on a plane
  public static let path: DataType = .init(_token: .path)

  /// Geometric point on a plane
  public static let point: DataType = .init(_token: .point)

  /// Closed geometric path on a plane
  public static let polygon: DataType = .init(_token: .polygon)

  /// Single precision floating-point number.
  public static let real: DataType = .init(_token: .real)
  public static let float4: DataType = real

  /// Signed two-byte integer.
  public static let smallInt: DataType = .init(_token: .smallint)
  public static let int2: DataType = smallInt

  /// Autoincrementing two-byte integer.
  public static let smallSerial: DataType = .init(_token: .smallserial)
  public static let serial2: DataType = smallSerial

  /// Autoincrementing four-byte integer.
  public static let serial: DataType = .init(_token: .serial)
  public static let serial4: DataType = serial

  /// Variable-length character string
  public static let text: DataType = .init(_token: .text)

  /// Time of day.
  public static func time(precision: Int? = nil, withTimeZone: Bool = false) throws -> DataType {
    var tokens: [SQLToken] = [.time]
    if let precision {
      try _appendParenthesizedPrecision(base: &tokens, precision: precision)
    }
    if withTimeZone {
      tokens.append(contentsOf: [.with, .time, .zone])
    }
    return .init(_tokens: tokens)
  }

  /// Date and time.
  public static func timestamp(precision: Int? = nil, withTimeZone: Bool = false) throws -> DataType {
    var tokens: [SQLToken] = [.timestamp]
    if let precision {
      try _appendParenthesizedPrecision(base: &tokens, precision: precision)
    }
    if withTimeZone {
      tokens.append(contentsOf: [.with, .time, .zone])
    }
    return .init(_tokens: tokens)
  }

  /// Text search query
  public static let textSearchQuery: DataType = .init(_token: .tsquery)

  /// Text search document
  public static let textSearchDocument: DataType = .init(_token: .tsvector)

  /// UUID
  public static let uuid: DataType = .init(_token: .uuid)

  /// XML
  public static let xml: DataType = .init(_token: .xml)
}
