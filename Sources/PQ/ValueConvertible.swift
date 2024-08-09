/* *************************************************************************************************
 ValueConvertible.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

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
  private var _byteSwapped: Self {
    return withUnsafePointer(to: self) { (myPointer: UnsafePointer<Self>) -> Self in
      func __swapBytesViaInt<T>(_ type: T.Type) -> Self where T: FixedWidthInteger {
        return myPointer.withMemoryRebound(to: type, capacity: 1) {
          return withUnsafePointer(to: $0.pointee.byteSwapped) {
            return $0.withMemoryRebound(to: Self.self, capacity: 1) { $0.pointee }
          }
        }
      }

      let size = MemoryLayout<Self>.size
      switch size {
      case 4:
        return __swapBytesViaInt(UInt32.self)
      case 8:
        return __swapBytesViaInt(UInt64.self)
      default:
        let destP = UnsafeMutableRawBufferPointer.allocate(
          byteCount: size,
          alignment: MemoryLayout<Self>.alignment
        )
        defer { destP.deallocate() }

        let srcP = UnsafeRawBufferPointer(start: UnsafeRawPointer(myPointer), count: size)
        for ii in 0..<size {
          destP[ii] = srcP[size - ii - 1]
        }
        return destP.bindMemory(to: Self.self).baseAddress!.pointee
      }
    }
  }

  private var _bigEndian: Self {
    switch ByteOrder.current {
    case .unknown:
      fatalError("Unknown host endianness.")
    case .littleEndian:
      return _byteSwapped
    case .bigEndian:
      return self
    }
  }

  private var _littleEndian: Self {
    switch ByteOrder.current {
    case .unknown:
      fatalError("Unknown host endianness.")
    case .littleEndian:
      return self
    case .bigEndian:
      return _byteSwapped
    }
  }

  private init(_bigEndian bigEndian: Self) {
    switch ByteOrder.current {
    case .unknown:
      fatalError("Unknown host endianness.")
    case .littleEndian:
      self = bigEndian._byteSwapped
    case .bigEndian:
      self = bigEndian
    }
  }

  public var sqlBinaryData: BinaryRepresentation? {
    return withUnsafePointer(to: self._bigEndian) { .init(copyingBytes: $0) }
  }

  public init?(sqlBinaryData data: BinaryRepresentation) {
    guard data.count == MemoryLayout<Self>.size else {
      return nil
    }
    var bigEndian = Self(0)
    withUnsafeBytes(of: &bigEndian) {
      let count = data.copyBytes(to: UnsafeMutableRawBufferPointer(mutating: $0))
      assert(MemoryLayout<Self>.size == count, "Unexpected length?!")
    }
    self.init(_bigEndian: bigEndian)
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

extension String: ValueConvertible {
  public static let oid: OID = .text
  
  public var sqlBinaryData: BinaryRepresentation? {
    return .init(data: Data(self.utf8))
  }
  
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self.init(data: data.data, encoding: .utf8)
  }
}
