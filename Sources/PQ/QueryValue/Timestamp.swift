/* *************************************************************************************************
 Timestamp.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import Foundation

/// A type that corresponds to `timestamp` PostgreSQL type.
public struct Timestamp: QueryValueConvertible, Equatable {
  /// Time interval with units of microseconds since Postgres Epoch (`2000-01-01 00:00:00+00`).
  public var timeIntervalSincePostgresEpoch: Int64

  public init(timeIntervalSincePostgresEpoch: Int64) {
    self.timeIntervalSincePostgresEpoch = timeIntervalSincePostgresEpoch
  }

  public var oid: OID { .timestamp }

  public var sqlStringValue: String? {
    let cString = _SwiftPQ_PGTYPES_timestamp_to_cString(timeIntervalSincePostgresEpoch)
    defer {
      _SwiftPQ_PGTYPES_free_cString(cString)
    }
    return String(cString: cString)
  }

  public init?(sqlStringValue string: String) {
    let resultPtr = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
    defer {
      resultPtr.deallocate()
    }

    guard let result = string.withCString({
      _SwiftPQ_PGTYPES_timestamp_from_cString($0, resultPtr)
    }) else {
      return nil
    }
    assert(result == resultPtr)
    self.init(timeIntervalSincePostgresEpoch: result.pointee)
  }

  public var sqlBinaryData: BinaryRepresentation? {
    return timeIntervalSincePostgresEpoch.sqlBinaryData
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard let pgTimestamp = Int64(sqlBinaryData: data) else {
      return nil
    }
    self.init(timeIntervalSincePostgresEpoch: pgTimestamp)
  }

  public static let postgresEpoch: Timestamp = .init(timeIntervalSincePostgresEpoch: 0)
}
