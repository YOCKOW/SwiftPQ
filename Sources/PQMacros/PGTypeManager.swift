/* *************************************************************************************************
 OIDManager.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CPostgreSQL
import Foundation
import SystemPackage

public typealias OID = Int32

private extension RawRepresentable where Self.RawValue == Character, Self: Decodable {
  init(_from container: any SingleValueDecodingContainer) throws {
    let desc = try container.decode(String.self)
    guard let character = desc.first, desc.dropFirst().isEmpty else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: container.codingPath, debugDescription: "Not a character?!")
      )
    }
    guard let instance = Self(rawValue: character) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: container.codingPath, debugDescription: "Unexpected character?!")
      )
    }
    self = instance
  }
}

/// `pg_type` described in https://www.postgresql.org/docs/16/catalog-pg-type.html
public struct PGTypeInfo: Decodable {
  enum Key: String, CodingKey {
    case arrayTypeOID = "array_type_oid"
    case description = "descr"
    case oid
    case typeAlignment = "typalign"
    case typeByValue = "typbyval"
    case typeCategory = "typcategory"
    case typeInput = "typinput"
    case typeIsPreferred = "typispreferred"
    case typeLength = "typlen"
    case typeName = "typname"
    case typeOutput = "typoutput"
    case typeReceive = "typreceive"
    case typeSend = "typsend"
  }

  public enum TypeAlignment: Character, Decodable {
    case char = "c"
    case short = "s"
    case int = "i"
    case double = "d"

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)
      if string == "ALIGNOF_POINTER" {
        switch MemoryLayout<UnsafeRawPointer>.alignment {
        case MemoryLayout<CChar>.alignment:
          self = .char
        case MemoryLayout<CShort>.alignment:
          self = .short
        case MemoryLayout<CInt>.alignment:
          self = .int
        case MemoryLayout<CDouble>.alignment:
          self = .double
        default:
          throw DecodingError.dataCorrupted(
            .init(
              codingPath: container.codingPath,
              debugDescription: "No type matching its alignment with pointer's one."
            )
          )
        }
      } else {
        try self.init(_from: container)
      }
    }
  }

  public enum TypeCategory: Character, Decodable {
    case array = "A"
    case boolean = "B"
    case composite = "C"
    case dateTime = "D"
    case `enum` = "E"
    case geometric = "G"
    case networkAddress = "I"
    case numeric = "N"
    case pseudo = "P"
    case range = "R"
    case string = "S"
    case timespan = "T"
    case userDefined = "U"
    case bitString = "V"
    case unknown = "X"
    case internalUse = "Z"

    public init(from decoder: any Decoder) throws {
      try self.init(_from: decoder.singleValueContainer())
    }
  }

  public let arrayTypeOID: OID?
  public let description: String?
  public let oid: OID
  public let typeAlignment: TypeAlignment
  public let typeByValue: Bool
  public let typeCategory: TypeCategory
  public let typeInput: String
  public let typeIsPreferred: Bool?
  public let typeLength: Int
  public let typeName: String
  public let typeOutput: String
  public let typeReceive: String
  public let typeSend: String

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)


    func __notBoolError(for key: Key) -> some Error {
      return DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Not boolean?!"
      )
    }
    func __bool(from string: String) -> Bool? {
      switch string {
      case "t":
        return true
      case "f":
        return false
      case "FLOAT8PASSBYVAL":
        return _SwiftPQ_get_FLOAT8PASSBYVAL()
      default:
        return nil
      }
    }
    func __decodeBool(for key: Key) throws -> Bool {
      guard let boolValue = try __bool(from:container.decode(String.self, forKey: key)) else {
        throw __notBoolError(for: key)
      }
      return boolValue
    }
    func __decodeBoolIfPresent(for key: Key) throws -> Bool? {
      return try container.decodeIfPresent(String.self, forKey: key).map {
        guard let boolValue = __bool(from: $0) else {
          throw __notBoolError(for: key)
        }
        return boolValue
      }
    }

    func __notIntegerError(for key: Key) -> some Error {
      return DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Not integer?!"
      )
    }
    func __int<I>(from string: String, type: I.Type) -> I? where I: FixedWidthInteger {
      switch string {
      case "NAMEDATALEN":
        return I(_SwiftPQ_get_NAMEDATALEN())
      case "SIZEOF_POINTER":
        return I(MemoryLayout<UnsafeRawPointer>.size)
      default:
        return I(string)
      }
    }
    func __decodeInt<I>(_ intType: I.Type, for key: Key) throws -> I where I: FixedWidthInteger {
      guard let int = __int(from: try container.decode(String.self, forKey: key), type: I.self) else {
        throw __notIntegerError(for: key)
      }
      return int
    }
    func __decodeIntIfPresent<I>(_ intType: I.Type, for key: Key) throws -> I? where I: FixedWidthInteger {
      guard let intDesc = try container.decodeIfPresent(String.self, forKey: key) else {
        return nil
      }
      guard let int = __int(from: intDesc, type: I.self) else {
        throw __notIntegerError(for: key)
      }
      return int
    }

    self.arrayTypeOID = try __decodeIntIfPresent(OID.self, for: .arrayTypeOID)
    self.description = try container.decodeIfPresent(String.self, forKey: .description)
    self.oid = try __decodeInt(OID.self, for: .oid)
    self.typeAlignment = try container.decode(TypeAlignment.self, forKey: .typeAlignment)
    self.typeByValue = try __decodeBool(for: .typeByValue)
    self.typeCategory = try container.decode(TypeCategory.self, forKey: .typeCategory)
    self.typeInput = try container.decode(String.self, forKey: .typeInput)
    self.typeIsPreferred = try __decodeBoolIfPresent(for: .typeIsPreferred)
    self.typeLength = try __decodeInt(Int.self, for: .typeLength)
    self.typeName = try container.decode(String.self, forKey: .typeName)
    self.typeOutput = try container.decode(String.self, forKey: .typeOutput)
    self.typeReceive = try container.decode(String.self, forKey: .typeReceive)
    self.typeSend = try container.decode(String.self, forKey: .typeSend)
  }
}

public struct PGTypeList: Decodable {
  public let oidToInfo: [OID: PGTypeInfo]
  public let nameToInfo: [String: PGTypeInfo]

  enum Key: CodingKey {
    case oidToInfo
    case nameToInfo
  }

  struct OIDKey: CodingKey {
    let oid: OID

    var stringValue: String { oid.description }
    init?(stringValue: String) {
      guard let oid = OID(stringValue) else { return nil }
      self.oid = oid
    }

    var intValue: Int? { Int(oid) }
    init?(intValue: Int) {
      self.oid = OID(intValue)
    }
  }

  struct TypeNameKey: CodingKey {
    let typeName: String
    var stringValue: String { typeName }
    init?(stringValue: String) {
      self.typeName = stringValue
    }

    var intValue: Int? { nil }
    init?(intValue: Int) {
      return nil
    }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)

    let oidToInfoContainer = try container.nestedContainer(keyedBy: OIDKey.self, forKey: .oidToInfo)
    let nameToInfoContainer = try container.nestedContainer(keyedBy: TypeNameKey.self, forKey: .nameToInfo)

    self.oidToInfo = try oidToInfoContainer.allKeys.reduce(into: [:]) {
      let oid = $1.oid
      $0[oid] = try oidToInfoContainer.decode(PGTypeInfo.self, forKey: $1)
    }
    self.nameToInfo = try nameToInfoContainer.allKeys.reduce(into: [:]) {
      let typeName = $1.typeName
      $0[typeName] = try nameToInfoContainer.decode(PGTypeInfo.self, forKey: $1)
    }
  }
}

public final class PGTypeManager {
  private init() {}
  public static let `default`: PGTypeManager = .init()

  private var _list: PGTypeList? = nil
  public var list: PGTypeList {
    get throws {
      guard let list = _list else {
        let fd = try FileDescriptor.open(pgTypeJSONFilePath, .readOnly)
        try fd.closeAfter {
          let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1024 * 1024, alignment: 8)
          defer { buffer.deallocate() }

          let count = try fd.read(into: buffer)
          let data = Data(buffer[0..<count])
          _list = try JSONDecoder().decode(PGTypeList.self, from: data)
        }
        return _list!
      }
      return list
    }
  }
}
