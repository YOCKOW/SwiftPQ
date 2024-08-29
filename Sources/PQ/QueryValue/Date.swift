/* *************************************************************************************************
 Date.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import Foundation

public typealias FoundationDate = Foundation.Date

extension _SwiftPQ_PGTYPES_YMD: Equatable {
  public static func ==(lhs: _SwiftPQ_PGTYPES_YMD, rhs: _SwiftPQ_PGTYPES_YMD) -> Bool {
    return (
      lhs.year == rhs.year
      && lhs.month == rhs.month
      && lhs.day == rhs.day
    )
  }
}

private final class _PGYMDBox: Equatable {
  private var _pgDate: Optional<Int32>

  private var _ymd: Optional<_SwiftPQ_PGTYPES_YMD>

  init(pgDate: Int32) {
    _pgDate = pgDate
    _ymd = nil
  }

  init(year: CInt, month: CInt, day: CInt) {
    _pgDate = nil
    _ymd = _SwiftPQ_PGTYPES_YMD(year: year, month: month, day: day)
  }

  var pgDate: Int32 {
    guard let pgDate = _pgDate else {
      guard let ymd = _ymd else { fatalError("Missing _ymd?!") }

      let pgDatePtr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
      defer {
        pgDatePtr.deallocate()
      }
      withUnsafePointer(to: ymd) {
        _SwiftPQ_PGTYPES_date_from_ymd($0, pgDatePtr)
      }
      let pgDate = pgDatePtr.pointee
      _pgDate = pgDate
      return pgDate
    }
    return pgDate
  }

  var ymd: _SwiftPQ_PGTYPES_YMD {
    guard let ymd = _ymd else {
      guard let pgDate = _pgDate else { fatalError("Missing _pgDate?!") }
      let ymdPtr = UnsafeMutablePointer<_SwiftPQ_PGTYPES_YMD>.allocate(capacity: 1)
      defer {
        ymdPtr.deallocate()
      }
      _SwiftPQ_PGTYPES_date_to_ymd(pgDate, ymdPtr)
      let ymd = ymdPtr.pointee
      _ymd = ymd
      return ymd
    }
    return ymd
  }
  var year: CInt { ymd.year }
  var month: CInt { ymd.month }
  var day: CInt { ymd.day }

  private var _description: String?
  var description: String {
    guard let description = _description else {
      let cString = _SwiftPQ_PGTYPES_date_to_cString(pgDate)
      defer {
        _SwiftPQ_PGTYPES_free_cString(cString)
      }
      let description = String(cString: cString)
      _description = description
      return description
    }
    return description
  }

  static func ==(lhs: _PGYMDBox, rhs: _PGYMDBox) -> Bool {
    if let lPGDate = lhs._pgDate {
      return lPGDate == rhs.pgDate
    }
    return lhs.ymd == rhs.ymd
  }
}

/// A type that corresponds to PostgreSQL's `date` type.
public struct Date: Equatable,
                    LosslessStringConvertible,
                    LosslessQueryBinaryDataConvertible,
                    LosslessQueryStringConvertible {
  public var oid: OID { .date }

  private var _box: _PGYMDBox

  public static func ==(lhs: Date, rhs: Date) -> Bool {
    return lhs._box == rhs._box
  }

  private init(pgDate: Int32) {
    self._box = _PGYMDBox(pgDate: pgDate)
  }

  public init(year: Int, month: Int, day: Int) {
    self._box = _PGYMDBox(year: CInt(year), month: CInt(month), day: CInt(day))
  }

  public var yearMonthDay: (year: Int, month: Int, day: Int) {
    get {
      return (year: Int(_box.year), month: Int(_box.month), day: Int(_box.day))
    }
    set {
      self._box = _PGYMDBox(
        year: CInt(newValue.year),
        month: CInt(newValue.month),
        day: CInt(newValue.day)
      )
    }
  }

  public var year: Int {
    get {
      return Int(_box.year)
    }
    set {
      self._box = _PGYMDBox(year: CInt(newValue), month: _box.month, day: _box.day)
    }
  }

  public var month: Int {
    get {
      return Int(_box.month)
    }
    set {
      self._box = _PGYMDBox(year: _box.year, month: CInt(newValue), day: _box.day)
    }
  }

  public var day: Int {
    get {
      return Int(_box.day)
    }
    set {
      self._box = _PGYMDBox(year: _box.year, month: _box.month, day: CInt(newValue))
    }
  }

  public var sqlBinaryData: BinaryRepresentation {
    return _box.pgDate.sqlBinaryData
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard let pgDate = data.as(Int32.self) else {
      return nil
    }
    self.init(pgDate: pgDate)
  }

  public var description: String {
    return _box.description
  }

  public init?(_ string: String) {
    let pgDatePtr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    defer {
      pgDatePtr.deallocate()
    }
    guard let parsedPtr = _SwiftPQ_PGTYPES_date_from_cString(string, pgDatePtr) else {
      return nil
    }
    assert(pgDatePtr == parsedPtr)
    self.init(pgDate: pgDatePtr.pointee)
  }
}
