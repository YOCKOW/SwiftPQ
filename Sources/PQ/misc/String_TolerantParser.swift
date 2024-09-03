/* *************************************************************************************************
 String_TolerantParser.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

internal extension Unicode.Scalar {
  var _isASCIINumber: Bool {
    return ("0"..."9").contains(self)
  }

  var _intValue: UInt8 {
    assert(_isASCIINumber)
    return UInt8(self.value - 0x30)
  }

  var _isASCIIUppercase: Bool {
    return ("A"..."Z").contains(self)
  }

  var _isASCIILowercase: Bool {
    return ("a"..."z").contains(self)
  }

  var _isAvailableInTimeZoneIdentifier: Bool {
    return (
      self._isASCIINumber
      || self._isASCIIUppercase
      || self._isASCIILowercase
      || self == "/"
      || self == "_"
      || self == "-"
      || self == "+"
    )
  }
}

internal extension StringProtocol {
  func _parseInt(
    from index: Index,
    maxNumberOfDigits: Int,
    skippableScalars: ((Unicode.Scalar) -> Bool)? = nil
  ) -> (int: Int, endIndex: Index)? {
    var result: Int = 0
    var count = 0
    var currentIndex = index
    let scalars = self.unicodeScalars

    while currentIndex < scalars.endIndex && count < maxNumberOfDigits {
      let scalar = scalars[currentIndex]
      if count == 0, let allower = skippableScalars, allower(scalar) {
        scalars.formIndex(after: &currentIndex)
        continue
      }
      guard scalar._isASCIINumber else {
        break
      }
      result = result * 10 + Int(scalar._intValue)
      scalars.formIndex(after: &currentIndex)
      count += 1
    }
    if count == 0 {
      return nil
    }
    return (result, currentIndex)
  }

  /// Parse fraction description that starts with ".".
  func _parseFraction(
    from index: Index,
    maxNumberOfDigits: Int
  ) -> (fraction: Decimal, endIndex: Index)? {
    var currentIndex = index
    let scalars = self.unicodeScalars

    guard currentIndex < scalars.endIndex, scalars[currentIndex] == "." else {
      return nil
    }
    let dotIndex = currentIndex
    scalars.formIndex(after: &currentIndex)

    var count = 0
    var fractionRoundEndIndex: String.Index? = nil
    while currentIndex < scalars.endIndex {
      let scalar = scalars[currentIndex]
      guard scalar._isASCIINumber else {
        break
      }
      count += 1
      scalars.formIndex(after: &currentIndex)
      if count == maxNumberOfDigits + 1 {
        fractionRoundEndIndex = currentIndex
      }
    }
    guard count > 0 else {
      return nil
    }
    let fractionEndIndex = currentIndex
    currentIndex = fractionRoundEndIndex ?? fractionEndIndex


    var fraction: Decimal = 0
    scalars.formIndex(before: &currentIndex)
    while currentIndex > dotIndex {
      let scalar = scalars[currentIndex]
      fraction += Decimal(scalar._intValue)
      guard let newFraction = try? fraction._multiplyByPowerOf10(-1) else {
        return nil
      }
      fraction = newFraction
      scalars.formIndex(before: &currentIndex)
    }
    return (
      fraction: count > maxNumberOfDigits ? fraction._rounded(maxNumberOfDigits) : fraction,
      endIndex: fractionEndIndex
    )
  }

  func _parseAMPM(
    from index: Index,
    skippableScalars: ((Unicode.Scalar) -> Bool)? = nil
  ) -> (_AMPM, endIndex: Index)? {
    var currentIndex = index
    let scalars = self.unicodeScalars

    if let allower = skippableScalars {
       while currentIndex < scalars.endIndex {
         let scalar = scalars[currentIndex]
         guard allower(scalar) else {
           break
         }
         scalars.formIndex(after: &currentIndex)
      }
    }
    guard currentIndex < scalars.endIndex else {
      return nil
    }
    let nextIndex = scalars.index(after: currentIndex)
    guard nextIndex < scalars.endIndex else {
      return nil
    }
    let firstScalar = scalars[currentIndex]
    let secondScalar = scalars[nextIndex]
    guard secondScalar == "M" || secondScalar == "m" else {
      return nil
    }
    let ampmEndIndex = scalars.index(after: nextIndex)

    switch firstScalar {
    case "A", "a":
      return (.am, endIndex: ampmEndIndex)
    case "P", "p":
      return (.pm, endIndex: ampmEndIndex)
    default:
      return nil
    }
  }

  /// Parse an abbreviated name of the time zone. i.g. `JST`.
  func _parseTimeZoneAbbreviation(
    from index: Index,
    skippableScalars: ((Unicode.Scalar) -> Bool)? = nil
  ) -> (timeZone: TimeZone, endIndex: Index)? {
    var abbr = String.UnicodeScalarView()
    var count = 0
    var currentIndex = index
    let scalars = self.unicodeScalars

    while currentIndex < scalars.endIndex && count < 4 {
      let scalar = scalars[currentIndex]
      if count == 0, let allower = skippableScalars, allower(scalar) {
        scalars.formIndex(after: &currentIndex)
        continue
      }
      guard scalar._isASCIIUppercase else {
        break
      }
      abbr.append(scalar)
      scalars.formIndex(after: &currentIndex)
      count += 1
    }
    guard count > 0, let timeZone = TimeZone(abbreviation: String(abbr)) else {
      return nil
    }
    return (timeZone: timeZone, endIndex: currentIndex)
  }

  /// Parse an identifier of the time zone. i.g. `Asia/Tokyo`
  func _parseTimeZoneIdentifier(
    from index: Index,
    skippableScalars: ((Unicode.Scalar) -> Bool)? = nil
  ) -> (timeZone: TimeZone, endIndex: Index)? {
    var identifier = String.UnicodeScalarView()
    var count = 0
    var currentIndex = index
    let scalars = self.unicodeScalars

    while currentIndex < scalars.endIndex {
      let scalar = scalars[currentIndex]
      if count == 0 {
        if let allower = skippableScalars, allower(scalar) {
          scalars.formIndex(after: &currentIndex)
          continue
        }
        guard scalar._isASCIIUppercase else {
          return nil
        }
      }
      guard scalar._isAvailableInTimeZoneIdentifier else {
        break
      }
      identifier.append(scalar)
      scalars.formIndex(after: &currentIndex)
      count += 1
    }
    guard count > 0, let timeZone = TimeZone(identifier: String(identifier)) else {
      return nil
    }
    return (timeZone: timeZone, endIndex: currentIndex)
  }

  /// Parse signed offset: `{-|+}hh[[:]mm[[:]ss]]`. i.g. `+9`, `-02`, `+08:30`, `-07:15:30`.
  func _parseTimeZoneUTCOffset(
    from index: Index,
    skippableScalars: ((Unicode.Scalar) -> Bool)? = nil
  ) -> (timeZone: TimeZone, endIndex: Index)? {
    var currentIndex = index
    let scalars = self.unicodeScalars

    if let allower = skippableScalars {
      while currentIndex < scalars.endIndex {
        let scalar = scalars[currentIndex]
        guard scalar != "-" && scalar != "+" && allower(scalar) else {
          break
        }
        scalars.formIndex(after: &currentIndex)
      }
    }
    guard currentIndex < scalars.endIndex else {
      return nil
    }

    guard let signIsMinus = ({ () -> Bool? in
      switch scalars[currentIndex] {
      case "-":
        return true
      case "+":
        return false
      default:
        return nil
      }
    })() else {
      return nil
    }
    scalars.formIndex(after: &currentIndex)
    guard currentIndex < scalars.endIndex else {
      return nil
    }

    guard let parsedHourInfo = _parseInt(from: currentIndex, maxNumberOfDigits: 2) else {
      return nil
    }
    let parsedMinuteInfo = _parseInt(
      from: parsedHourInfo.endIndex,
      maxNumberOfDigits: 2,
      skippableScalars: { $0 == ":" }
    )
    let parsedSecondInfo: (int: Int, endIndex: Index)? = parsedMinuteInfo.flatMap {
      _parseInt(from: $0.endIndex, maxNumberOfDigits: 2, skippableScalars: { $0 == ":" })
    }

    let secondsFromGMT: Int = (
      parsedHourInfo.int * 3600
      + ((parsedMinuteInfo?.int ?? 0) * 60)
      + ((parsedSecondInfo?.int ?? 0))
    ) * (signIsMinus ? -1 : 1)
    guard let timeZone = TimeZone(secondsFromGMT: secondsFromGMT) else {
      return nil
    }

    let endIndex: Index = (
      parsedSecondInfo?.endIndex
      ?? parsedMinuteInfo?.endIndex
      ?? parsedHourInfo.endIndex
    )
    return (timeZone: timeZone, endIndex: endIndex)
  }

  func _detectTimeZone(from index: Index) -> (timeZone: TimeZone, endIndex: Index)? {
    guard index < self.endIndex else {
      return nil
    }

    return (
      _parseTimeZoneIdentifier(from: index, skippableScalars: { $0 == " " })
      ?? _parseTimeZoneAbbreviation(from: index, skippableScalars: { $0 == " " })
      ?? _parseTimeZoneUTCOffset(from: index, skippableScalars: { $0 == " " })
    )
  }
}
