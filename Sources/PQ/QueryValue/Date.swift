/* *************************************************************************************************
 Date.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import Foundation

public typealias FoundationDate = Foundation.Date

/// A type that corresponds to PostgreSQL's `date` type.
public struct Date: Equatable,
                    LosslessStringConvertible,
                    LosslessQueryBinaryDataConvertible,
                    LosslessQueryStringConvertible {
  public let oid: OID = .date

  private var _pgDate: Int32

  private init(pgDate: Int32) {
    self._pgDate = pgDate
  }

  public var yearMonthDay: (year: Int, month: Int, day: Int) {
    let ymdPtr = UnsafeMutablePointer<_SwiftPQ_YMD>.allocate(capacity: 1)
    defer {
      ymdPtr.deallocate()
    }
    _SwiftPQ_PGTYPES_date_to_ymd(_pgDate, ymdPtr)
    let ymd = ymdPtr.pointee
    return (year: Int(ymd.year), month: Int(ymd.month), day: Int(ymd.day))
  }

  public init(year: Int, month: Int, day: Int) {
    let pgDatePtr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    defer {
      pgDatePtr.deallocate()
    }
    let ymd = _SwiftPQ_YMD(year: CInt(year), month: CInt(month), day: CInt(day))
    withUnsafePointer(to: ymd) {
      _SwiftPQ_PGTYPES_date_from_ymd($0, pgDatePtr)
    }
    self.init(pgDate: pgDatePtr.pointee)
  }

  public var sqlBinaryData: BinaryRepresentation {
    return _pgDate.sqlBinaryData
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard let pgDate = data.as(Int32.self) else {
      return nil
    }
    self.init(pgDate: pgDate)
  }

  public var description: String {
    let cString = _SwiftPQ_PGTYPES_date_to_cString(_pgDate)
    defer {
      _SwiftPQ_PGTYPES_free_cString(cString)
    }
    return String(cString: cString)
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
