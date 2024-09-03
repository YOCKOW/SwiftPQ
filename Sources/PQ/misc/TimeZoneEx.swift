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
