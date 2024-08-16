/* *************************************************************************************************
 QueryValue.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibECPG
import Foundation
import yExtensions

/// A single field value of a row.
public enum QueryValue: CustomDebugStringConvertible {
  case text(String)
  case binary(BinaryRepresentation)

  public init?<T>(_ value: T) where T: QueryValueConvertible {
    if let binary = value.sqlBinaryData {
      self = .binary(binary)
    } else if let string = value.sqlStringValue {
      self = .text(string)
    } else {
      return nil
    }
  }

  public func `as`<T>(_ type: T.Type) -> T? where T: QueryValueConvertible {
    switch self {
    case .text(let string):
      return T(sqlStringValue: string)
    case .binary(let data):
      return data.as(type)
    }
  }

  public var data: Data {
    switch self {
    case .text(let string):
      return Data(string.utf8) + CollectionOfOne<UInt8>(0x00)
    case .binary(let representation):
      return representation.data
    }
  }

  public var debugDescription: String {
    switch self {
    case .text(let string):
      return string
    case .binary(let representation):
      return representation.debugDescription
    }
  }
}

/// A type that can be converted to a SQL parameter value
///
/// At least either `sqlStringValue` or `sqlBinaryData` must be not `nil`.
public protocol QueryValueConvertible {
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
  public func `as`<V>(_ type: V.Type) -> V? where V: QueryValueConvertible {
    return V(sqlBinaryData: self)
  }
}

extension QueryValueConvertible where Self: CustomStringConvertible {
  public var sqlStringValue: String? {
    return String(describing: self)
  }
}

extension QueryValueConvertible where Self: LosslessStringConvertible {
  public init?(sqlStringValue: String) {
    self.init(sqlStringValue)
  }
}

extension QueryValueConvertible where Self: FixedWidthInteger {
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

extension QueryValueConvertible where Self: FloatingPoint {
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

extension Bool: QueryValueConvertible {
  public static let oid: OID = .bool

  @inlinable
  public init?(sqlStringValue: String) {
    if sqlStringValue.isEmpty {
      return nil
    }
    guard sqlStringValue.compareCount(with: 6) == .orderedAscending else {
      return nil
    }
    switch sqlStringValue.lowercased() {
    case "true", "yes", "on", "1", "t", "y":
      self = true
    case "false", "no", "off", "0", "f", "n":
      self = false
    default:
      return nil
    }
  }

  @inlinable
  public var sqlBinaryData: BinaryRepresentation? {
    let byte: UInt8 = self ? 1 : 0
    return BinaryRepresentation(data: Data([byte]))
  }

  @inlinable
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self = data.allSatisfy({ $0 == 0 }) ? false : true
  }
}

extension Int8: QueryValueConvertible {
  public static let oid: OID = .char
}

extension UInt8: QueryValueConvertible {
  public static let oid: OID = .char
}

extension Int16: QueryValueConvertible {
  public static let oid: OID = .int2
}

extension UInt16: QueryValueConvertible {
  public static let oid: OID = .int2
}

extension Int32: QueryValueConvertible {
  public static let oid: OID = .int4
}

extension UInt32: QueryValueConvertible {
  public static let oid: OID = .int4
}

extension Int64: QueryValueConvertible {
  public static let oid: OID = .int8
}

extension UInt64: QueryValueConvertible {
  public static let oid: OID = .int8
}

extension Int: QueryValueConvertible {
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

extension UInt: QueryValueConvertible {
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

extension Float: QueryValueConvertible {
  public static let oid: OID = .float4
}

extension Double: QueryValueConvertible {
  public static let oid: OID = .float8
}

extension Decimal: QueryValueConvertible {
  public static let oid: OID = .numeric

  public init?(sqlStringValue: String) {
    self.init(string: sqlStringValue, locale: Locale(identifier: "en_US"))
  }

  private var _floor: Decimal  {
    let resultPtr = UnsafeMutablePointer<Decimal>.allocate(capacity: 1)
    defer { resultPtr.deallocate() }

    withUnsafePointer(to: self) {
      NSDecimalRound(resultPtr, $0, 0, .down)
    }

    return resultPtr.pointee
  }

  private var _floorAndFraction: (floor: Decimal, fraction: Decimal) {
    let floor = self._floor
    return (floor: floor, fraction: self - floor)
  }

  private var _fraction: Decimal {
    return self._floorAndFraction.fraction
  }


  private var _isInteger: Bool {
    return self == self._floor
  }

  private struct _CalculationError: Error {
    let error: CalculationError
  }
  private func _multiplyByPowerOf10(
    _ power: Int16,
    rounding roundingMode: RoundingMode = .down
  ) throws -> Decimal {
    let resultPtr = UnsafeMutablePointer<Decimal>.allocate(capacity: 1)
    defer { resultPtr.deallocate() }

    let error = withUnsafePointer(to: self) {
      return NSDecimalMultiplyByPowerOf10(resultPtr, $0, power, roundingMode)
    }
    switch error {
    case .noError:
      break
    default:
      throw _CalculationError(error: error)
    }

    return resultPtr.pointee
  }

  private var _int16Value: Int16 {
    return (self as NSDecimalNumber).int16Value
  }

  public var sqlBinaryData: BinaryRepresentation? {
    guard self.isNaN || self.isFinite else {
      return nil
    }

    // Implementation note:
    // Binary representation for `decimal` is `NumericVar` without `buf`.
    // https://github.com/postgres/postgres/blob/e3ec9dc1bf4983fcedb6f43c71ea12ee26aefc7a/src/backend/utils/adt/numeric.c#L312-L320
    // https://github.com/postgres/postgres/blob/e3ec9dc1bf4983fcedb6f43c71ea12ee26aefc7a/src/backend/utils/adt/numeric.c#L1161-L1184

    var nDigits: Int16 = 0
    var weight: Int16 = 0
    var signFlag: Int16 = 0
    var dScale: Int16 = 0
    var digits: [Int16] = []

    CONVERT_DECIMAL_TO_PQ_FORMAT: do {
      if self.isNaN {
        signFlag = Int16(NUMERIC_NAN)
        break CONVERT_DECIMAL_TO_PQ_FORMAT
      }

      if self == 0 {
        nDigits = 1
        weight = 1
        digits.append(0x0000)
        break CONVERT_DECIMAL_TO_PQ_FORMAT
      }

      let absDecimal = ({
        switch self.sign {
        case .plus:
          signFlag = Int16(NUMERIC_POS)
          return self
        case .minus:
          signFlag = Int16(NUMERIC_NEG)
          return -self
        }
      })()

      if absDecimal.significand._isInteger {
        if absDecimal.exponent < 0 {
          dScale = Int16(absDecimal.exponent * -1)
        }
      } else {
        var tmpDecimal = absDecimal._fraction
        while !tmpDecimal._isInteger {
          guard let next = try? tmpDecimal._multiplyByPowerOf10(1) else {
            return nil
          }
          dScale += 1
          tmpDecimal = next
        }
      }

      var consumingDecimal = absDecimal
      while consumingDecimal >= 1 {
        guard let next = try? consumingDecimal._multiplyByPowerOf10(-4) else {
          return nil
        }
        weight += 1
        consumingDecimal = next
      }
      nDigits = weight + ((dScale == 0) ? 0 : ((dScale - 1) / 4) + 1)

      assert(consumingDecimal._floor == 0, "Unexpected initial value: \(consumingDecimal)")
      for _ in 0..<nDigits {
        guard let x10000 = try? consumingDecimal._multiplyByPowerOf10(4) else {
          return nil
        }
        let (floor, fraction) = x10000._floorAndFraction
        assert(floor < 10000, "Unexpected floor value: \(floor)")
        digits.append(floor._int16Value)
        consumingDecimal = fraction
      }
      assert(digits.count == nDigits, "Unexpected number of digits.")
    }

    // FINALIZE
    var data = Data()
    func __append(_ int16: Int16) {
      withUnsafePointer(to: int16.bigEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: 2) {
          data.append($0[0])
          data.append($0[1])
        }
      }
    }
    __append(nDigits)
    __append(weight - 1)
    __append(signFlag)
    __append(dScale)
    digits.forEach({ __append($0) })
    return BinaryRepresentation(data: data)
  }
  
  public init?(sqlBinaryData data: BinaryRepresentation) {
    // `data` is considered as an array of 16-bit integers. First four of them are header.
    guard data.count > 8, data.count.isMultiple(of: 2) else {
      return nil
    }
    let count16 = data.count / 2

    guard let decimal: Decimal = data.withUnsafeBytes({
      return $0.withMemoryRebound(to: Int16.self) { (buffer: UnsafeBufferPointer<Int16>) -> Decimal? in
        let signFlag = Int16(bigEndian: buffer[2])
        if signFlag == NUMERIC_NAN {
          return .nan
        }
        guard let sign: FloatingPointSign = ({ () -> FloatingPointSign? in
          switch signFlag {
          case Int16(NUMERIC_POS):
            return .plus
          case Int16(NUMERIC_NEG):
            return .minus
          default:
            return nil
          }
        })() else {
          return nil
        }

        let nDigits = Int16(bigEndian: buffer[0])
        guard nDigits > 0, count16 >= nDigits + 4 else {
          return nil
        }
        var weight = Int16(bigEndian: buffer[1]) + 1
        let dScale = Int16(bigEndian: buffer[3])
        let fnDigits = (dScale == 0) ? 0 : ((dScale - 1) / 4) + 1
        assert(nDigits == weight + fnDigits, "Unexpected length.")

        return buffer.withMemoryRebound(to: UInt16.self) { (buffer: UnsafeBufferPointer<UInt16>) -> Decimal? in
          var result: Decimal = 0
          var fractionPartCount = 1
          for ii in 4..<(4 + Int(nDigits)) {
            let currentPart = Decimal(UInt16(bigEndian: buffer[ii]))
            guard currentPart < 10000 else {
              return nil
            }
            if weight > 0 {
              result = result * 10000 + currentPart
              weight -= 1
            } else {
              result += currentPart * pow(
                Decimal(sign: .plus, exponent: -4, significand: 1),
                fractionPartCount
              )
              fractionPartCount += 1
            }
          }
          if sign == .minus {
            result.negate()
          }
          return result
        }
      }
    }) else {
      return nil
    }
    self = decimal
  }
}

extension String: QueryValueConvertible {
  public static let oid: OID = .text
  
  public var sqlBinaryData: BinaryRepresentation? {
    return .init(data: Data(self.utf8))
  }
  
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self.init(data: data.data, encoding: .utf8)
  }
}
