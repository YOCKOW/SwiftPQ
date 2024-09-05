/* *************************************************************************************************
 TimeZoneEx.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

internal extension TimeZone {
  func _utcOffsetIsEqual(to other: TimeZone) -> Bool {
    return self.secondsFromGMT() == other.secondsFromGMT()
  }

  func _offsetDescription(for foundationDate: FoundationDate? = nil) -> String {
    let secondsFromGMT = foundationDate.map({ self.secondsFromGMT(for: $0) }) ?? self.secondsFromGMT()
    var desc = secondsFromGMT > 0 ? "+" : "-"

    func __append(_ int: Int) {
      if int < 10 {
        desc += "0"
      }
      desc += String(int, radix: 10)
    }

    let (hourOffset, hRemainder) = abs(secondsFromGMT).quotientAndRemainder(dividingBy: 3600)
    __append(hourOffset)

    let (minOffset, secOffset) = hRemainder.quotientAndRemainder(dividingBy: 60)
    guard minOffset > 0 else {
      return desc
    }
    __append(minOffset)

    guard secOffset > 0 else {
      return desc
    }
    __append(secOffset)

    return desc
  }
}

internal extension Time {
  func _timeZoneIsEqual(to other: Time) -> Bool {
    if let myTimeZone = self.timeZone {
      guard let otherTimeZone = other.timeZone else {
        return false
      }
      return myTimeZone._utcOffsetIsEqual(to: otherTimeZone)
    }
    return other.timeZone == nil
  }
}

internal extension Timestamp {
  func _timeZoneIsEqual(to other: Timestamp) -> Bool {
    if let myTimeZone = self.timeZone {
      guard let otherTimeZone = other.timeZone else {
        return false
      }
      return (
        myTimeZone.secondsFromGMT(for: self.foundationDate)
        == otherTimeZone.secondsFromGMT(for: other.foundationDate)
      )
    }
    return other.timeZone == nil
  }
}
