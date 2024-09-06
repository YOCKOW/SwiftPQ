/* *************************************************************************************************
 Interval.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import yExtensions

extension _SwiftPQ_PGTYPES_Interval: Equatable {
  public static func ==(lhs: _SwiftPQ_PGTYPES_Interval, rhs: _SwiftPQ_PGTYPES_Interval) -> Bool {
    return lhs.time == rhs.time && lhs.month == rhs.month
  }
}

/// A type that corresponds to PostgreSQL's `interval` type.
///
/// - Note: This type always treats a day as 24 hours.
public struct Interval: Equatable,
                        LosslessStringConvertible,
                        LosslessQueryStringConvertible {
  public var oid: OID { .interval }

  private let _interval: _SwiftPQ_PGTYPES_Interval

  public static func ==(lhs: Interval, rhs: Interval) -> Bool {
    return lhs._interval == rhs._interval
  }

  public var description: String {
    return withUnsafePointer(to: _interval) {
      let cString = _SwiftPQ_PGTYPES_interval_to_cString($0)
      defer {
        _SwiftPQ_PGTYPES_free_cString(cString)
      }
      return String(cString: cString)
    }
  }

  public init?(_ description: String) {
    let intervalPtr = UnsafeMutablePointer<_SwiftPQ_PGTYPES_Interval>.allocate(capacity: 1)
    defer {
      intervalPtr.deallocate()
    }

    guard let resultPtr = description.withCString({
      return _SwiftPQ_PGTYPES_interval_from_cString($0, intervalPtr)
    }) else {
      return nil
    }
    assert(intervalPtr == resultPtr)

    self._interval = intervalPtr.pointee
  }

  public init(
    millenniums: Int = 0,
    centuries: Int = 0,
    decades: Int = 0,
    years: Int = 0,
    months: Int = 0,
    weeks: Int = 0,
    days: Int = 0,
    hours: Int = 0,
    minutes: Int = 0,
    seconds: Int = 0,
    milliseconds: Int = 0,
    microseconds: Int = 0
  ) {
    var interval = _SwiftPQ_PGTYPES_Interval(time: 0, month: 0)

    let nCenturies = Int32(millenniums) * 10 + Int32(centuries)
    let nDecades = nCenturies * 10 + Int32(decades)
    let nYears = nDecades * 10 + Int32(years)
    interval.month = nYears * 12 + Int32(months)

    let nDays: Int64 = Int64(weeks) * 7 + Int64(days)
    let nHours: Int64 = nDays * 24 + Int64(hours)
    let nMinutes: Int64 = nHours * 60 + Int64(minutes)
    let nSeconds: Int64 = nMinutes * 60 + Int64(seconds)
    let nMilliseconds: Int64 = nSeconds * 1000 + Int64(milliseconds)
    interval.time = nMilliseconds * 1000 + Int64(microseconds)

    self._interval = interval
  }
}

extension Interval: LosslessQueryBinaryDataConvertible {
  // Implementation Note:
  //   `_SwiftPQ_PGTYPES_Interval` has only two fields: `time` and `month`,
  //   while `Interval`(PG server) has three fields: `time`, `day`, and `month`.

  private static let _microsecondsPerDay: Int64 = 24 * 60 * 60 * 1_000_000

  public var sqlBinaryData: BinaryRepresentation {
    let (day, rTime) = _interval.time.quotientAndRemainder(dividingBy: Interval._microsecondsPerDay)
    return rTime.sqlBinaryData + Int32(day).sqlBinaryData + _interval.month.sqlBinaryData
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard data.count == 16,
          let time = Int64(sqlBinaryData: data[relativeBounds: 0..<8]),
          let day = Int32(sqlBinaryData: data[relativeBounds: 8..<12]),
          let month = Int32(sqlBinaryData: data[relativeBounds: 12..<16]) else {
      return nil
    }
    var interval = _SwiftPQ_PGTYPES_Interval(time: time, month: month)
    interval.time += Int64(day) * Interval._microsecondsPerDay
    self._interval = interval
  }
}
