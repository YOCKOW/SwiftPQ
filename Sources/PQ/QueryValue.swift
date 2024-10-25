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
public struct QueryValue: CustomDebugStringConvertible, Sendable {
  /// Representation of the acutual query value.
  public enum Payload: Sendable {
    /// Text format representation.
    case text(String)

    /// Binary format representation.
    case binary(BinaryRepresentation)

    public var data: Data {
      switch self {
      case .text(let string):
        return Data(string.utf8) + CollectionOfOne<UInt8>(0x00)
      case .binary(let representation):
        return representation.data
      }
    }

    @inlinable
    public var isText: Bool {
      guard case .text = self else {
        return false
      }
      return true
    }

    @inlinable
    public var isBinary: Bool {
      guard case .binary = self else {
        return false
      }
      return true
    }
  }

  public let oid: OID

  public let payload: Payload?

  @inlinable
  public init(oid: OID, payload: Payload?) {
    self.oid = oid
    self.payload = payload
  }

  @inlinable
  public init(oid: OID, string: String) {
    self.oid = oid
    self.payload = .text(string)
  }

  @inlinable
  public init(oid: OID, binary: BinaryRepresentation) {
    self.oid = oid
    self.payload = .binary(binary)
  }

  public var debugDescription: String {
    var desc = "OID: \(oid.rawValue)\n"
    switch payload {
    case .text(let string):
      desc += string
    case .binary(let representation):
      desc += representation.debugDescription
    case nil:
      desc += "<no data>"
    }
    return desc
  }
}

// MARK: - Protocol definitions

/// A type that can be converted to a SQL parameter value.
public protocol CustomQueryValueConvertible {
  /// An Object Identifier for this instance.
  var oid: OID { get }

  /// A payload of the query value.
  var payload: QueryValue.Payload? { get }

  /// A query value.
  ///
  /// Default implementation provided.
  var queryValue: QueryValue { get }
}

/// A type that can be converted to a SQL parameter value with string representation.
public protocol CustomQueryStringConvertible: CustomQueryValueConvertible {
  /// A string value for SQL text format.
  var sqlStringValue: String { get }
}

/// A type that can be converted to a SQL parameter value with binary representation.
public protocol CustomQueryBinaryDataConvertible: CustomQueryValueConvertible {
  /// Binary data for SQL binary format.
  var sqlBinaryData: BinaryRepresentation { get }
}

/// A type that can be represented as a query value in a lossless, unambiguous way.
public protocol LosslessQueryValueConvertible: CustomQueryValueConvertible {
  /// Instantiates an instance of the conforming type from query value.
  init?(_ value: QueryValue)
}

/// A type that can be represented as a SQL parameter string in a lossless, unambiguous way.
public protocol LosslessQueryStringConvertible: CustomQueryStringConvertible,
                                                LosslessQueryValueConvertible {
  /// Instantiates an instance of the conforming type from a SQL string representation.
  init?(sqlStringValue: String)
}

/// A type that can be represented as SQL parameter binary data in a lossless, unambiguous way.
public protocol LosslessQueryBinaryDataConvertible: CustomQueryBinaryDataConvertible,
                                                    LosslessQueryValueConvertible {
  /// Instantiates an instance of the conforming type from a SQL binary representation.
  init?(sqlBinaryData: BinaryRepresentation)
}


// MARK: - Protocol extensions

extension CustomQueryValueConvertible {
  @inlinable
  public var queryValue: QueryValue {
    return QueryValue(oid: self.oid, payload: self.payload)
  }
}

extension CustomQueryStringConvertible {
  @inlinable
  public var payload: QueryValue.Payload? {
    return .text(self.sqlStringValue)
  }
}

extension CustomQueryBinaryDataConvertible {
  @inlinable
  public var payload: QueryValue.Payload? {
    return .binary(self.sqlBinaryData)
  }
}

extension CustomQueryStringConvertible where Self: CustomStringConvertible {
  @inlinable
  public var sqlStringValue: String {
    return String(describing: self)
  }
}

extension CustomQueryStringConvertible where Self: CustomQueryBinaryDataConvertible {
  /// A query value with binary format.
  @inlinable
  public var payload: QueryValue.Payload? {
    return .binary(self.sqlBinaryData)
  }
}

extension LosslessQueryStringConvertible {
  public init?(_ value: QueryValue) {
    guard case .text(let string) = value.payload else {
      return nil
    }
    self.init(sqlStringValue: string)
  }
}

extension LosslessQueryBinaryDataConvertible {
  public init?(_ value: QueryValue) {
    guard case .binary(let data) = value.payload else {
      return nil
    }
    self.init(sqlBinaryData: data)
  }
}

extension LosslessQueryStringConvertible where Self: LosslessQueryBinaryDataConvertible {
  public init?(_ value: QueryValue) {
    switch value.payload {
    case .text(let string):
      self.init(sqlStringValue: string)
    case .binary(let data):
      self.init(sqlBinaryData: data)
    default:
      return nil
    }
  }
}

extension LosslessQueryStringConvertible where Self: LosslessStringConvertible {
  @inlinable
  public init?(sqlStringValue: String) {
    self.init(sqlStringValue)
  }
}

extension CustomQueryBinaryDataConvertible where Self: FixedWidthInteger {
  public var sqlBinaryData: BinaryRepresentation {
    return withUnsafePointer(to: self.bigEndian) { .init(copyingBytes: $0) }
  }
}

extension LosslessQueryBinaryDataConvertible where Self: FixedWidthInteger {
  @inlinable
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

extension CustomQueryBinaryDataConvertible where Self: FloatingPoint {
  fileprivate var _byteSwapped: Self {
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

  public var sqlBinaryData: BinaryRepresentation {
    return withUnsafePointer(to: self._bigEndian) { .init(copyingBytes: $0) }
  }
}

extension LosslessQueryBinaryDataConvertible where Self: FloatingPoint {
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

// MARK: - Existing type extensions

extension BinaryRepresentation {
  public func `as`<T>(_ type: T.Type) -> T? where T: LosslessQueryBinaryDataConvertible {
    return T(sqlBinaryData: self)
  }
}

extension QueryValue {
  public func `as`<T>(_ type: T.Type) -> T? where T: LosslessQueryValueConvertible {
    return T(self)
  }
}

extension QueryValue: CustomQueryValueConvertible {
  @inlinable
  public var queryValue: QueryValue {
    return self
  }
}

extension Bool: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .bool }

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
  public var sqlBinaryData: BinaryRepresentation {
    let byte: UInt8 = self ? 1 : 0
    return BinaryRepresentation(data: Data([byte]))
  }

  @inlinable
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self = data.allSatisfy({ $0 == 0 }) ? false : true
  }
}

extension Int8: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .char }
}

extension UInt8: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .char }
}

extension Int16: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .int2 }
}

extension UInt16: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .int2 }
}

extension Int32: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .int4 }
}

extension UInt32: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .int4 }
}

extension Int64: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .int8 }
}

extension UInt64: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .int8 }
}

extension Int: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID {
    switch MemoryLayout<Int>.size {
    case 4:
      return .int4
    case 8:
      return .int8
    default:
      fatalError("Unsupported architecture.")
    }
  }
}

extension UInt: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID {
    switch MemoryLayout<Int>.size {
    case 4:
      return .int4
    case 8:
      return .int8
    default:
      fatalError("Unsupported architecture.")
    }
  }
}

extension Float: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .float4 }
}

extension Double: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .float8 }
}

extension Decimal: LosslessQueryStringConvertible {
  public var oid: OID { .numeric }

  public init?(sqlStringValue: String) {
    self.init(string: sqlStringValue, locale: Locale(identifier: "en_US"))
  }

  internal var _floor: Decimal  {
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

  internal func _multiplyByPowerOf10(
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

  internal func _rounded(_ scale: Int, rounding roundingMode: RoundingMode = .plain) -> Decimal {
    let resultPtr = UnsafeMutablePointer<Decimal>.allocate(capacity: 1)
    defer { resultPtr.deallocate() }

    withUnsafePointer(to: self) {
      NSDecimalRound(resultPtr, $0, scale, roundingMode)
    }
    return resultPtr.pointee
  }

  private var _int16Value: Int16 {
    return (self as NSDecimalNumber).int16Value
  }

  internal var _intValue: Int {
    return (self as NSDecimalNumber).intValue
  }

  public var binaryData: BinaryRepresentation? {
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
  
  public init?(_ data: BinaryRepresentation) {
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

  public var payload: QueryValue.Payload? {
    if let data = binaryData {
      return .binary(data)
    }
    return .text(sqlStringValue)
  }

  public init?(_ value: QueryValue) {
    switch value.payload {
    case .text(let string):
      self.init(sqlStringValue: string)
    case .binary(let data):
      self.init(data)
    default:
      return nil
    }
  }
}

extension String: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .text }

  public var sqlBinaryData: BinaryRepresentation {
    return .init(data: Data(self.utf8))
  }
  
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self.init(data: data.data, encoding: .utf8)
  }
}

extension Data: LosslessQueryStringConvertible, LosslessQueryBinaryDataConvertible {
  public var oid: OID { .bytea }

  public var sqlStringValue: String {
    return "\\x" + self.flatMap { (byte: UInt8) -> String in
      let hex = String(byte, radix: 16, uppercase: false)
      if byte < 0x10 {
        return "0\(hex)"
      }
      return hex
    }
  }

  public init?(sqlStringValue string: String) {
    if string.hasPrefix("\\x") {
      self.init()
      var currentIndex = string.index(string.startIndex, offsetBy: 2)
      while currentIndex < string.endIndex {
        let nextIndex = string.index(after: currentIndex)
        guard nextIndex < string.endIndex else {
          return nil
        }
        guard let byte = UInt8(string[currentIndex...nextIndex], radix: 16) else {
          return nil
        }
        self.append(byte)
        currentIndex = string.index(after: nextIndex)
      }
    } else {
      // TODO?: Support for `bytea_output = 'escape'`??
      return nil
    }
  }

  public var sqlBinaryData: BinaryRepresentation {
    return BinaryRepresentation(data: self)
  }
  
  public init?(sqlBinaryData data: BinaryRepresentation) {
    self.init(data)
  }
}
