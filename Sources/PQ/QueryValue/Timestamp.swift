/* *************************************************************************************************
 Timestamp.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import Foundation

private func _parseTimestamp(_ description: String) -> (timestamp: Int64, timeZone: TimeZone?)? {
  let possibleIndexOfTimeZoneSeparator = description.lastIndex(where: {
    $0 == " " || $0 == "-" || $0 == "+"
  })
  let parsedTZInfo = possibleIndexOfTimeZoneSeparator.flatMap {
    description._detectTimeZone(from: $0)
  }
  let timeZone: TimeZone? = parsedTZInfo.flatMap {
    guard $0.endIndex == description.endIndex else {
      return nil
    }
    return $0.timeZone
  }

  let timestampPtr = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
  defer {
    timestampPtr.deallocate()
  }
  let descEndIndex = timeZone == nil ? description.endIndex : possibleIndexOfTimeZoneSeparator!
  let descRange = description.startIndex..<descEndIndex
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
public struct Timestamp: LosslessQueryStringConvertible,
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
  public init(_ date: FoundationDate, timeZone: TimeZone? = nil) {
    self.init(
      timeIntervalSincePostgresEpoch: (
        Int64(date.timeIntervalSinceReferenceDate * 1000000)
        + Timestamp.foundationDateEpoch.timeIntervalSincePostgresEpoch
      ),
      timeZone: timeZone
    )
  }

  @inlinable
  public var foundationDate: FoundationDate {
    return FoundationDate(
      timeIntervalSinceReferenceDate: Double(
        self.timeIntervalSincePostgresEpoch
        - Timestamp.foundationDateEpoch.timeIntervalSincePostgresEpoch
      ) / 1000000.0
    )
  }
}

extension Timestamp: Equatable {
  public static func ==(lhs: Timestamp, rhs: Timestamp) -> Bool {
    return (
      lhs.timeIntervalSincePostgresEpoch == rhs.timeIntervalSincePostgresEpoch
      && lhs._timeZoneIsEqual(to: rhs)
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
