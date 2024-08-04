/* *************************************************************************************************
 OIDManager.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CPostgreSQL
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SystemPackage

public typealias OID = Int32

private enum _CharacterDecodingError: LocalizedError {
  case notCharacter
  case unexpectedCharacter

  var errorDescription: String? {
    switch self {
    case .notCharacter:
      return "Not a character?!"
    case .unexpectedCharacter:
      return "Unexpected character?!"
    }
  }
}
private protocol _DecodableRawCharacterRepresentable: Decodable, RawRepresentable where Self.RawValue == Character {
  init(from string: String) throws
}
extension _DecodableRawCharacterRepresentable {
  init(_string string: String) throws {
    guard let character = string.first, string.dropFirst().isEmpty else {
      throw _CharacterDecodingError.notCharacter
    }
    guard let instance = Self(rawValue: character) else {
      throw _CharacterDecodingError.unexpectedCharacter
    }
    self = instance
  }

  init(_from container: any SingleValueDecodingContainer) throws {
    let desc = try container.decode(String.self)
    do {
      try self.init(_string: desc)
    } catch let error as _CharacterDecodingError {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: container.codingPath,
          debugDescription: error.errorDescription!,
          underlyingError: error
        )
      )
    }
  }

  init(from string: String) throws {
    try self.init(_string: string)
  }

  public init(from decoder: any Decoder) throws {
    try self.init(_from: decoder.singleValueContainer())
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

  public enum TypeAlignment: Character, Decodable, _DecodableRawCharacterRepresentable {
    case char = "c"
    case short = "s"
    case int = "i"
    case double = "d"

    private enum _Error: LocalizedError {
      case alignmentOfPointerError

      var errorDescription: String? {
        switch self {
        case .alignmentOfPointerError:
          return "No type matching its alignment with pointer's one."
        }
      }
    }

    init(from description: String) throws {
      if description == "ALIGNOF_POINTER" {
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
          throw _Error.alignmentOfPointerError
        }
      } else {
        try self.init(_string: description)
      }
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)
      do {
        try self.init(from: string)
      } catch let error as _Error {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: container.codingPath,
            debugDescription: error.errorDescription!
          )
        )
      }
      try self.init(_from: container)
    }
  }

  public enum TypeCategory: Character, Decodable, _DecodableRawCharacterRepresentable {
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

  private enum _Container {
    case decoding(KeyedDecodingContainer<Key>)
    case dictionary([String: String])

    enum DictionaryError: Error {
      case dataCorruptedError(forKey: Key, in: [String: String], debugDescription: String)
      case missingKeyError(forKey: Key, in: [String: String])
    }

    func error(for key: Key, debugDescription: String) -> any Error {
      switch self {
      case .decoding(let keyedDecodingContainer):
        return DecodingError.dataCorruptedError(
          forKey: key,
          in: keyedDecodingContainer,
          debugDescription: debugDescription
        )
      case .dictionary(let dictionary):
        return DictionaryError.dataCorruptedError(
          forKey: key,
          in: dictionary,
          debugDescription: debugDescription
        )
      }
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
      switch self {
      case .decoding(let keyedDecodingContainer):
        return try keyedDecodingContainer.decode(String.self, forKey: key)
      case .dictionary(let dictionary):
        guard let value = dictionary[key.rawValue] else {
          throw DictionaryError.missingKeyError(forKey: key, in: dictionary)
        }
        return value
      }
    }

    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
      switch self {
      case .decoding(let keyedDecodingContainer):
        return try keyedDecodingContainer.decodeIfPresent(String.self, forKey: key)
      case .dictionary(let dictionary):
        return dictionary[key.rawValue]
      }
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: _DecodableRawCharacterRepresentable {
      switch self {
      case .decoding(let keyedDecodingContainer):
        return try keyedDecodingContainer.decode(T.self, forKey: key)
      case .dictionary(let dictionary):
        guard let value = dictionary[key.rawValue] else {
          throw DictionaryError.missingKeyError(forKey: key, in: dictionary)
        }
        return try T.init(from: value)
      }
    }
  }

  private init(_from container: _Container) throws {
    func __notBoolError(for key: Key) -> any Error {
      return container.error(for: key, debugDescription: "Not Boolean?!")
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
      return container.error(for: key, debugDescription: "Not integer?!")
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    try self.init(_from: .decoding(container))
  }

  public init(_ dictionary: [String: String]) throws {
    try self.init(_from: .dictionary(dictionary))
  }
}

public struct PGTypeList: Decodable {
  public let oidToInfo: [OID: PGTypeInfo]
  public let nameToInfo: [String: PGTypeInfo]

  enum Key: String, CodingKey {
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

  public init(_ dictionary: [String: [String: [String: String]]]) throws {
    enum __Error: Error {
      case missingOidToInfo
      case missingNameToInfo
    }
    guard let oidToInfoDict = dictionary[Key.oidToInfo.rawValue] else {
      throw __Error.missingOidToInfo
    }
    guard let nameToInfoDict = dictionary[Key.nameToInfo.rawValue] else {
      throw __Error.missingNameToInfo
    }
    self.oidToInfo = try oidToInfoDict.reduce(into: [:]) {
      let info = try PGTypeInfo($1.value)
      $0[info.oid] = info
    }
    self.nameToInfo = try nameToInfoDict.reduce(into: [:]) {
      let info = try PGTypeInfo($1.value)
      $0[info.typeName] = info
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
        // Macros are executed in a sandbox.
        /*
        let fd = try FileDescriptor.open(pgTypeJSONFilePath, .readOnly)
        try fd.closeAfter {
          let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1024 * 1024, alignment: 8)
          defer { buffer.deallocate() }

          let count = try fd.read(into: buffer)
          let data = Data(buffer[0..<count])
          _list = try JSONDecoder().decode(PGTypeList.self, from: data)
        }
        return _list!
         */

        _list = try PGTypeList(pgTypeMap)
        return _list!
      }
      return list
    }
  }
}

/// Expand static members of `OID`.
///
/// - Note: Only for the purpose of internal use.
public struct OIDExpander: MemberMacro {
  public enum Error: Swift.Error {
    case unsupportedType
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let oidStructDecl = declaration.as(StructDeclSyntax.self),
          oidStructDecl.name.text == "OID",
          (oidStructDecl.inheritanceClause?.inheritedTypes.contains(where: {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text == "RawRepresentable"
          }) == true)
    else {
      throw Error.unsupportedType
    }

    var result: [DeclSyntax] = []

    let list = try PGTypeManager.default.list
    for oid in list.oidToInfo.keys.sorted(by: <) {
      let info = list.oidToInfo[oid]!
      let name = info.typeName
      let swId = name._swiftIdentifier

      result.append("""
      /// OID for `\(raw: name)` type.
      public static let \(swId): OID = .init(rawValue: \(raw: oid))
      """)
    }

    return result
  }
}
