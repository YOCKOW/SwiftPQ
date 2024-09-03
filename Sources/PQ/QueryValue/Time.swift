/* *************************************************************************************************
 Time.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

internal enum _AMPM {
  case am
  case pm
}

private final class _PGTimeBox: Equatable {
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

  private var _pgTime: Optional<Int64>

  private var _hmsf: Optional<HMSF>

  init(pgTime: Int64) {
    self._pgTime = pgTime
    self._hmsf = nil
  }

  init(hour: Int, minute: Int, second: Int, microsecond: Int) {
    self._pgTime = nil
    self._hmsf = .init(hour: hour, minute: minute, second: second, microsecond: microsecond)
  }

  var pgTime: Int64 {
    if _pgTime == nil {
      _pgTime = _hmsf!.pgTime
    }
    return _pgTime!
  }

  var hmsf: HMSF {
    if _hmsf == nil {
      _hmsf = HMSF(pgTime: _pgTime!)
    }
    return _hmsf!
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
    if let lPGTime = lhs._pgTime {
      return lPGTime == rhs.pgTime
    }
    return lhs.hmsf == rhs.hmsf
  }
}

/// A type that corresponds to PostgreSQL's `time` or `time with time zone` type.
public struct Time: Equatable, LosslessStringConvertible, LosslessQueryStringConvertible {
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
    return _box.description
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
}
