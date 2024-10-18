/* *************************************************************************************************
 Time.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

internal enum _AMPM {
  case am
  case pm
}

private final class _PGTimeBox: Equatable, @unchecked Sendable {
  struct HMSF: Equatable {
    let hour: Int
    let minute: Int
    let second: Int
    let microsecond: Int

    init(hour: Int, minute: Int, second: Int, microsecond: Int) {
      self.hour = hour
      self.minute = minute
      self.second = second
      self.microsecond = microsecond
    }

    init(pgTime: Int64) {
      let (hour, hRemainder) = pgTime.quotientAndRemainder(dividingBy: 3600_000_000)
      let (minute, mRemainder) = hRemainder.quotientAndRemainder(dividingBy: 60_000_000)
      let (second, microsecond) = mRemainder.quotientAndRemainder(dividingBy: 1_000_000)
      self.init(
        hour: Int(hour),
        minute: Int(minute),
        second: Int(second),
        microsecond: Int(microsecond)
      )
    }

    var pgTime: Int64 {
      var result = Int64()
      result += Int64(hour * 3600_000_000)
      result += Int64(minute * 60_000_000)
      result += Int64(second * 1_000_000)
      result += Int64(microsecond)
      return result
    }
  }

  private struct _Properties: Sendable {
    var pgTime: Optional<Int64>
    var hmsf: Optional<HMSF>
    init(pgTime: Int64) {
      self.pgTime = pgTime
      self.hmsf = nil
    }
    init(hmsf: HMSF) {
      self.pgTime = nil
      self.hmsf = hmsf
    }
  }
  private var _properties: _Properties
  private let _queue: DispatchQueue = .init(
    label: "jp.YOCKOW.PQ._PGTimeBox",
    attributes: .concurrent
  )
  private func _withProperties<T>(_ work: (inout _Properties) throws -> T) rethrows -> T {
    return try _queue.sync(flags: .barrier, execute: { try work(&_properties) })
  }


  init(pgTime: Int64) {
    self._properties = .init(pgTime: pgTime)
  }

  init(hour: Int, minute: Int, second: Int, microsecond: Int) {
    self._properties = .init(
      hmsf: .init(
        hour: hour,
        minute: minute,
        second: second,
        microsecond: microsecond
      )
    )
  }

  var pgTime: Int64 {
    return _withProperties {
      guard let pgTime = $0.pgTime else {
        let pgTime = $0.hmsf!.pgTime
        $0.pgTime = pgTime
        return pgTime
      }
      return pgTime
    }
  }

  var hmsf: HMSF {
    return _withProperties {
      guard let hmsf = $0.hmsf else {
        let hmsf = HMSF(pgTime: $0.pgTime!)
        $0.hmsf = hmsf
        return hmsf
      }
      return hmsf
    }
  }

  var hour: Int { hmsf.hour }
  var minute: Int { hmsf.minute }
  var second: Int { hmsf.second }
  var microsecond: Int { hmsf.microsecond }

  private(set) lazy var description: String = ({
    let hmsf = self.hmsf

    func __02d(_ int: Int) -> String {
      assert(int < 100)
      if int < 10 {
        return "0\(int)"
      }
      return String(describing: int)
    }

    var result = "\(__02d(hmsf.hour)):\(__02d(hmsf.minute)):\(__02d(hmsf.second))"
    if hmsf.microsecond > 0 {
      assert(hmsf.microsecond < 1_000_000)
      result += "."

      var dividend = hmsf.microsecond
      var divisor = 100_000
      for _ in 0..<6 {
        let (qq, rr) = dividend.quotientAndRemainder(dividingBy: divisor)
        assert(qq >= 0 && qq < 10)
        result += String(describing: qq)
        if rr == 0 {
          break
        }
        dividend = rr
        divisor /= 10
      }
    }
    return result
  })()

  static func ==(lhs: _PGTimeBox, rhs: _PGTimeBox) -> Bool {
    return lhs._withProperties {
      if let lPGTime = $0.pgTime {
        return lPGTime == rhs.pgTime
      }
      return $0.hmsf == rhs.hmsf
    }
  }
}

/// A type that corresponds to PostgreSQL's `time` or `time with time zone` type.
public struct Time: Equatable, 
                    LosslessStringConvertible,
                    LosslessQueryStringConvertible,
                    LosslessQueryBinaryDataConvertible,
                    Sendable {
  private var _box: _PGTimeBox

  public var timeZone: Optional<TimeZone>

  public static func ==(lhs: Time, rhs: Time) -> Bool {
    return lhs._box == rhs._box && lhs._timeZoneIsEqual(to: rhs)
  }

  public init(hour: Int, minute: Int, second: Int, microsecond: Int = 0, timeZone: TimeZone? = nil) {
    self._box = _PGTimeBox(hour: hour, minute: minute, second: second, microsecond: microsecond)
    self.timeZone = timeZone
  }

  public var oid: OID {
    return timeZone == nil ? .time : .timetz
  }

  public var hour: Int {
    get {
      return _box.hour
    }
    set {
      self._box = _PGTimeBox(
        hour: newValue,
        minute: _box.minute,
        second: _box.second,
        microsecond: _box.microsecond
      )
    }
  }

  public var minute: Int {
    get {
      return _box.minute
    }
    set {
      self._box = _PGTimeBox(
        hour: _box.hour,
        minute: newValue,
        second: _box.second,
        microsecond: _box.microsecond
      )
    }
  }

  public var second: Int {
    get {
      return _box.second
    }
    set {
      self._box = _PGTimeBox(
        hour: _box.hour,
        minute: _box.minute,
        second: newValue,
        microsecond: _box.microsecond
      )
    }
  }

  public var microsecond: Int {
    get {
      return _box.microsecond
    }
    set {
      self._box = _PGTimeBox(
        hour: _box.hour,
        minute: _box.minute,
        second: _box.second,
        microsecond: newValue
      )
    }
  }

  public var description: String {
    guard let timeZone = self.timeZone else {
      return _box.description
    }
    return _box.description + timeZone._offsetDescription()
  }

  public init?(_ description: String) {
    var currentIndex = description.startIndex
    guard let parsedHourInfo = description._parseInt(from: currentIndex, maxNumberOfDigits: 2) else {
      return nil
    }
    var hour = parsedHourInfo.int
    guard hour >= 0 && hour <= 24 else {
      return nil
    }

    currentIndex = parsedHourInfo.endIndex
    guard let parsedMinuteInfo = description._parseInt(
      from: currentIndex,
      maxNumberOfDigits: 2,
      skippableScalars: { $0 == ":" }
    ) else {
      return nil
    }
    let minute = parsedMinuteInfo.int
    guard minute >= 0 && minute <= 60 else {
      return nil
    }

    currentIndex = parsedMinuteInfo.endIndex
    let parsedSecondInfo = description._parseInt(
      from: currentIndex,
      maxNumberOfDigits: 2,
      skippableScalars: { $0 == ":" }
    )
    let second = parsedSecondInfo?.int ?? 0
    guard second >= 0 && second <= 60 else {
      return nil
    }

    guard let microsecond: Int = ({ () -> Int? in
      guard let secondEndIndex = parsedSecondInfo?.endIndex else {
        return 0
      }
      currentIndex = secondEndIndex

      guard currentIndex < description.endIndex else {
        return 0
      }
      guard description[currentIndex] == "." else {
        return 0
      }
      guard let parsedFractionInfo = description._parseFraction(
        from: currentIndex,
        maxNumberOfDigits: 6
      ) else {
        return nil
      }
      guard let microsecond = try? parsedFractionInfo.fraction._multiplyByPowerOf10(6)._floor._intValue else {
        return nil
      }
      currentIndex = parsedFractionInfo.endIndex
      return microsecond
    })() else {
      return nil
    }

    if let ampmInfo = description._parseAMPM(from: currentIndex, skippableScalars: { $0 == " " }) {
      if case .pm = ampmInfo.0 {
        guard hour <= 12 else {
          return nil
        }
        hour += 12
      }
      currentIndex = ampmInfo.endIndex
    }

    let timeZone: TimeZone? = description._detectTimeZone(from: currentIndex).map {
      currentIndex = $0.endIndex
      return $0.timeZone
    }

    self.init(
      hour: hour,
      minute: minute,
      second: second,
      microsecond: microsecond,
      timeZone: timeZone
    )
  }

  public var sqlBinaryData: BinaryRepresentation {
    let pgTimeData = _box.pgTime.sqlBinaryData
    guard let timeZone = self.timeZone else {
      return pgTimeData
    }
    let timeZoneData = Int32(timeZone.secondsFromGMT() * -1).sqlBinaryData
    return BinaryRepresentation(data: pgTimeData.data + timeZoneData)
  }


  public init?(sqlBinaryData data: BinaryRepresentation) {
    switch data.count {
    case 8:
      guard let pgTime = Int64(sqlBinaryData: data) else {
        return nil
      }
      self._box = _PGTimeBox(pgTime: pgTime)
      self.timeZone = nil
    case 12:
      let pgTimeData = data[relativeBounds: 0..<8]
      let timeZoneData = data[relativeBounds: 8..<12]
      guard let pgTime = Int64(sqlBinaryData: pgTimeData) else {
        return nil
      }
      guard let timeZoneOffset = Int32(sqlBinaryData: timeZoneData),
            let timeZone = TimeZone(secondsFromGMT: Int(timeZoneOffset) * -1) else {
        return nil
      }
      self._box = _PGTimeBox(pgTime: pgTime)
      self.timeZone = timeZone
    default:
      return nil
    }
  }
}
