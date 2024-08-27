/* *************************************************************************************************
 Timestamp.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import Foundation

/// Detect the time zone _tolerantly_ with one of formats below.
///
/// Supported time zone formats:
/// - Abbreviated name. i.g. `JST`.
/// - Signed offset: `{-|+}hh[[:]mm[[:]ss]]`. i.g. `+9`, `-02`, `+08:30`, `-07:15:30`.
private func _detectTimeZone(from pgDescription: String) -> (timeZone: TimeZone, range: Range<String.Index>)? {
  guard let tzFirstIndex = pgDescription.lastIndex(where: { $0 == " " || $0 == "-" || $0 == "+" }) else {
    return nil
  }

  let tzRange = tzFirstIndex..<pgDescription.endIndex
  let tzFirstChar = pgDescription[tzFirstIndex]
  switch tzFirstChar {
  case " ":
    // Parse abbr name
    let abbrFirstIndex = pgDescription.index(after: tzFirstIndex)
    guard abbrFirstIndex < pgDescription.endIndex else {
      return nil
    }
    let abbr = String(pgDescription[abbrFirstIndex...])
    guard let timeZone = TimeZone(abbreviation: abbr) else {
      return nil
    }
    return (timeZone, tzRange)
  case "-", "+":
    // Parse offset
    let plus: Bool = tzFirstChar == "+"

    var currentIndex = pgDescription.index(after: tzFirstIndex)
    func __advance() {
      currentIndex = pgDescription.index(after: currentIndex)
    }
    func __parseInt(allowColon: Bool) -> Int? {
      var result: Int = 0
      var count = 0
      while currentIndex < pgDescription.endIndex && count < 2 {
        let char = pgDescription[currentIndex]
        if allowColon && char == ":" {
          __advance()
          continue
        }
        guard let firstScalar = char.unicodeScalars.first,
              ("0"..."9").contains(firstScalar) else {
          return count > 0 ? result : nil
        }
        result = result * 10 + Int(firstScalar.value - 0x30)
        __advance()
        count += 1
      }
      return result
    }

    guard let hours = __parseInt(allowColon: false) else {
      return nil
    }
    let minutes = __parseInt(allowColon: true)
    let seconds: Int? = minutes == nil ? nil : __parseInt(allowColon: true)

    guard currentIndex == pgDescription.endIndex else {
      return nil
    }

    let secondsFromGMT = (hours * 3600 + ((minutes ?? 0) * 60) + (seconds ?? 0)) * (plus ? 1 : -1)
    guard let timeZone = TimeZone(secondsFromGMT: secondsFromGMT) else {
      return nil
    }
    return (timeZone, tzRange)
  default:
    return nil
  }
}

private func _parseTimestamp(_ description: String) -> (timestamp: Int64, timeZone: TimeZone?)? {
  let detectedTimeZoneAndRange = _detectTimeZone(from: description)
  let timeZone: TimeZone? = detectedTimeZoneAndRange?.timeZone

  let timestampPtr = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
  defer {
    timestampPtr.deallocate()
  }
  let descRange = description.startIndex..<((detectedTimeZoneAndRange?.range.lowerBound) ?? description.endIndex)
  guard let parseResultPtr = description[descRange].withCString({
    _SwiftPQ_PGTYPES_timestamp_from_cString($0, timestampPtr)
  }) else {
    return nil
  }
  assert(timestampPtr == parseResultPtr)

  var timestamp = timestampPtr.pointee
  if let timeZone {
    timestamp -= Int64(timeZone.secondsFromGMT()) * 1000000
  }
  return (timestamp, timeZone)
}

private func _dumpTimestamp(_ timestamp: Int64, timeZone: TimeZone?) -> String {
  let secondsFromGMT = Int64(timeZone?.secondsFromGMT() ?? 0)
  let timestampToDump = timestamp + (secondsFromGMT * 1000000)

  let cString = _SwiftPQ_PGTYPES_timestamp_to_cString(timestampToDump)
  defer {
    _SwiftPQ_PGTYPES_free_cString(cString)
  }

  var desc = String(cString: cString)
  TIME_ZONE_DESC: if timeZone != nil {
    desc += secondsFromGMT > 0 ? "+" : "-"

    func __append(_ int: Int64) {
      if int < 10 {
        desc += "0"
      }
      desc += String(int, radix: 10)
    }

    let (hourOffset, hRemainder) = abs(secondsFromGMT).quotientAndRemainder(dividingBy: 3600)
    __append(hourOffset)

    let (minOffset, secOffset) = hRemainder.quotientAndRemainder(dividingBy: 60)
    guard minOffset > 0 else {
      break TIME_ZONE_DESC
    }
    __append(minOffset)

    guard secOffset > 0 else {
      break TIME_ZONE_DESC
    }
    __append(secOffset)
  }
  return desc
}

/// A type that corresponds to PostgreSQL's `timestamp` or
/// `timestamptz`(a.k.a. `TIMESTAMP WITH TIME ZONE`) type.
///
/// - Note: PostgreSQL doesn't store any information about time zones for `timestamptz`. You have to
///         care about time zones when the value is converted to/from string.
public struct Timestamp: Equatable,
                         LosslessQueryStringConvertible,
                         LosslessQueryBinaryDataConvertible {
  /// Time interval with units of microseconds since Postgres Epoch (`2000-01-01 00:00:00+00`).
  public var timeIntervalSincePostgresEpoch: Int64

  public var timeZone: Optional<TimeZone>

  @inlinable
  public init(timeIntervalSincePostgresEpoch: Int64, timeZone: TimeZone? = nil) {
    self.timeIntervalSincePostgresEpoch = timeIntervalSincePostgresEpoch
    self.timeZone = timeZone
  }

  public var oid: OID { timeZone == nil ? .timestamp : .timestamptz }

  public var sqlStringValue: String {
    return _dumpTimestamp(timeIntervalSincePostgresEpoch, timeZone: timeZone)
  }

  public init?(_ description: String, timeZone: TimeZone? = nil) {
    guard let parsed = _parseTimestamp(description) else {
      return nil
    }
    switch (parsed.timeZone, timeZone) {
    case (_, nil):
      self.init(timeIntervalSincePostgresEpoch: parsed.timestamp, timeZone: parsed.timeZone)
    case (_?, let givenTimeZone?):
      self.init(timeIntervalSincePostgresEpoch: parsed.timestamp, timeZone: givenTimeZone)
    case (nil, let givenTimeZone?):
      let timestamp = parsed.timestamp - (Int64(givenTimeZone.secondsFromGMT()) * 1000000)
      self.init(timeIntervalSincePostgresEpoch: timestamp, timeZone: givenTimeZone)
    }
  }

  public init?(sqlStringValue string: String) {
    self.init(string, timeZone: nil)
  }

  public var sqlBinaryData: BinaryRepresentation {
    return timeIntervalSincePostgresEpoch.sqlBinaryData
  }

  @inlinable
  public init?(sqlBinaryData data: BinaryRepresentation, timeZone: TimeZone?) {
    guard let pgTimestamp = Int64(sqlBinaryData: data) else {
      return nil
    }
    self.init(timeIntervalSincePostgresEpoch: pgTimestamp, timeZone: timeZone)
  }

  @inlinable
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self.init(sqlBinaryData: data, timeZone: nil)
  }

  @inlinable
  public init?(_ value: QueryValue, timeZone: TimeZone?) {
    guard let payload = value.payload else {
      return nil
    }
    switch payload {
    case .text(let string):
      self.init(string, timeZone: timeZone)
    case .binary(let data):
      self.init(sqlBinaryData: data, timeZone: timeZone)
    }
  }

  @inlinable
  public init?(_ value: QueryValue) {
    self.init(value, timeZone: nil)
  }

  /// 00:00:00 UTC on 1 January 2000.
  public static let postgresEpoch: Timestamp = .init(timeIntervalSincePostgresEpoch: 0)

  /// 00:00:00 UTC on 1 January 1970.
  public static let unixEpoch: Timestamp = .init(timeIntervalSincePostgresEpoch: -946684800000000)
}

extension Timestamp {
  /// 00:00:00 UTC on 1 January 2001.
  public static let foundationDateEpoch: Timestamp = .init(timeIntervalSincePostgresEpoch: 31622400000000)

  @inlinable
  public init(_ date: Date, timeZone: TimeZone? = nil) {
    self.init(
      timeIntervalSincePostgresEpoch: (
        Int64(date.timeIntervalSinceReferenceDate * 1000000)
        + Timestamp.foundationDateEpoch.timeIntervalSincePostgresEpoch
      ),
      timeZone: timeZone
    )
  }
}

extension QueryValue {
  public func `as`(_ type: Timestamp.Type, timeZone: TimeZone?) -> Timestamp? {
    return Timestamp(self, timeZone: timeZone)
  }

  public func asTimestamp(withTimeZone timeZone: TimeZone? = nil) -> Timestamp? {
    return Timestamp(self, timeZone: timeZone)
  }
}
