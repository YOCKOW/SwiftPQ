/* *************************************************************************************************
 ValueConvertible.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// A type that can be converted to a SQL parameter value
///
/// At least either `sqlStringValue` or `sqlBinaryData` must be not `nil`.
public protocol ValueConvertible {
  /// An Object Identifier for this type.
  static var oid: OID { get }

  /// A string value for SQL text format.
  var sqlStringValue: String? { get }

  /// Initializes with a string value for SQL text format.
  init?(sqlStringValue: String)

  /// Binary data for SQL binary format.
  var sqlBinaryData: BinaryRepresentation? { get }

  /// Initializes with binary data for SQL binary format.
  init?(sqlBinaryData: BinaryRepresentation)
}

extension BinaryRepresentation {
  public func `as`<V>(_ type: V.Type) -> V? where V: ValueConvertible {
    return V(sqlBinaryData: self)
  }
}

extension ValueConvertible where Self: LosslessStringConvertible {
  public var sqlStringValue: String? {
    return self.description
  }

  public init?(sqlStringValue: String) {
    self.init(sqlStringValue)
  }
}

extension ValueConvertible where Self: FixedWidthInteger {
  public var sqlBinaryData: BinaryRepresentation? {
    return withUnsafePointer(to: self.bigEndian) { .init(copyingBytes: $0) }
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard data.count == MemoryLayout<Self>.size else {
      return nil
    }
    var bigEndian = Self()
    withUnsafeBytes(of: &bigEndian) {
      let count = data.copyBytes(to: UnsafeMutableRawBufferPointer(mutating: $0))
      assert(MemoryLayout<Self>.size == count, "Unexpected length?!")
    }
    self.init(bigEndian: bigEndian)
  }
}

extension ValueConvertible where Self: FloatingPoint {
  public var sqlBinaryData: BinaryRepresentation? {
    return withUnsafePointer(to: self) { .init(copyingBytes: $0) }
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard data.count == MemoryLayout<Self>.size else {
      return nil
    }
    self.init(0)
    withUnsafeBytes(of: &self) {
      let count = data.copyBytes(to: UnsafeMutableRawBufferPointer(mutating: $0))
      assert(MemoryLayout<Self>.size == count, "Unexpected length?!")
    }
  }
}

extension Int8: ValueConvertible {
  public static let oid: OID = .char
}

extension UInt8: ValueConvertible {
  public static let oid: OID = .char
}

extension Int16: ValueConvertible {
  public static let oid: OID = .int2
}

extension UInt16: ValueConvertible {
  public static let oid: OID = .int2
}

extension Int32: ValueConvertible {
  public static let oid: OID = .int4
}

extension UInt32: ValueConvertible {
  public static let oid: OID = .int4
}

extension Int64: ValueConvertible {
  public static let oid: OID = .int8
}

extension UInt64: ValueConvertible {
  public static let oid: OID = .int8
}

extension Int: ValueConvertible {
  public static let oid: OID = ({
    switch MemoryLayout<Int>.size {
    case 4:
      return .int4
    case 8:
      return .int8
    default:
      fatalError("Unsupported architecture.")
    }
  })()
}

extension UInt: ValueConvertible {
  public static let oid: OID = ({
    switch MemoryLayout<UInt>.size {
    case 4:
      return .int4
    case 8:
      return .int8
    default:
      fatalError("Unsupported architecture.")
    }
  })()
}

extension Float: ValueConvertible {
  public static let oid: OID = .float4
}

extension Double: ValueConvertible {
  public static let oid: OID = .float8
}
