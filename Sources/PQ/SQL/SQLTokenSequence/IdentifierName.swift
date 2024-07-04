/* *************************************************************************************************
 IdentifierName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

// TODO: Use macros?

private protocol _SQLIdentifierConvertibleToken where Self: SQLToken {}
extension SQLToken.Keyword: _SQLIdentifierConvertibleToken {}
extension SQLToken.Identifier: _SQLIdentifierConvertibleToken {}
extension SQLToken.DelimitedIdentifier: _SQLIdentifierConvertibleToken {}

/// A type that is expressed as an identifier in SQL.
public struct SQLIdentifierConvertibleString: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public enum InitializationError: Error {
    case unexpectedToken
  }

  private enum _Gut {
    case token(any _SQLIdentifierConvertibleToken)
    case string(String)
  }

  private let _gut: _Gut

  private init(gut: _Gut) {
    self._gut = gut
  }

  public var rawValue: String {
    switch _gut {
    case .token(let token):
      return token._rawValue
    case .string(let string):
      return string
    }
  }

  public var token: SQLToken {
    switch _gut {
    case .token(let token):
      return token
    case .string(let string):
      return .identifier(string)
    }
  }

  public init(_ token: SQLToken) throws {
    guard case let idToken as any _SQLIdentifierConvertibleToken = token else {
      throw InitializationError.unexpectedToken
    }
    self.init(gut: .token(idToken))
  }

  public init(_ string: String, caseSensitive: Bool = false, encodingIsUTF8: Bool = true) {
    if caseSensitive {
      let token = SQLToken.DelimitedIdentifier(rawValue: string, encodingIsUTF8: encodingIsUTF8)
      self.init(gut: .token(token))
    } else {
      self.init(gut: .string(string))
    }
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }
}

/// A column name.
public struct ColumnName: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  public typealias StringLiteralType = String

  public var name: SQLIdentifierConvertibleString

  public var token: SQLToken {
    return name.token
  }

  public init(_ name: SQLIdentifierConvertibleString) {
    self.name = name
  }

  public init(stringLiteral value: String) {
    self.name = .init(stringLiteral: value)
  }
}

/// A name used for `WITH` clause.
public struct WithQueryName: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  public typealias StringLiteralType = String

  public var name: SQLIdentifierConvertibleString

  public var token: SQLToken {
    return name.token
  }

  public init(_ name: SQLIdentifierConvertibleString) {
    self.name = name
  }

  public init(stringLiteral value: String) {
    self.name = .init(stringLiteral: value)
  }
}

public protocol SchemaQualifiedIdentifier: SQLTokenSequence {
  /// A name of schema.
  var schema: SQLIdentifierConvertibleString? { get }
  var name: SQLIdentifierConvertibleString { get }
  init(schema: SQLIdentifierConvertibleString?, name: SQLIdentifierConvertibleString)
}

extension SchemaQualifiedIdentifier {
  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    if let schema {
      tokens.append(contentsOf: [schema.token, .joiner, .dot, .joiner])
    }
    tokens.append(name.token)
    return tokens
  }

  internal init(name: SQLToken) {
    self.init(schema: nil, name: try! .init(name))
  }
}

/// A type that represents a name of function.
public struct FunctionName: SchemaQualifiedIdentifier {
  /// A name of schema.
  public var schema: SQLIdentifierConvertibleString?

  /// A name of the function.
  public var name: SQLIdentifierConvertibleString

  public init(schema: SQLIdentifierConvertibleString? = nil, name: SQLIdentifierConvertibleString) {
    self.schema = schema
    self.name = name
  }
}

public struct AggregateName: SchemaQualifiedIdentifier {
  /// A name of schema.
  public var schema: SQLIdentifierConvertibleString?

  /// A name of the aggregation.
  public var name: SQLIdentifierConvertibleString

  public init(schema: SQLIdentifierConvertibleString? = nil, name: SQLIdentifierConvertibleString) {
    self.schema = schema
    self.name = name
  }

  /// `ARRAY_AGG`
  public static let arrayAggregate: AggregateName = .init(name: .arrayAgg)

  /// `PERCENTILE_CONT`
  public static let continuousPercentile: AggregateName = .init(name: .percentileCont)

  /// `COUNT`
  public static let count: AggregateName = .init(name: .count)

  /// `STRING_AGG`
  public static let stringAggregate: AggregateName = .init(name: .stringAgg)

  /// `XMLAGG`
  public static let xmlAggregate: AggregateName = .init(name: .xmlagg)
}

public struct CollationName: SchemaQualifiedIdentifier {
  public var schema: SQLIdentifierConvertibleString?

  public var name: SQLIdentifierConvertibleString

  public init(schema: SQLIdentifierConvertibleString? = nil, name: SQLIdentifierConvertibleString) {
    self.schema = schema
    self.name = name
  }

  /// Use ANSI C locale for collation.
  public static let c: CollationName = .init(name: SQLIdentifierConvertibleString("C", caseSensitive: true))

  /// Use POSIX locale for collation.
  public static let posix: CollationName = .init(name: SQLIdentifierConvertibleString("POSIX", caseSensitive: true))

  /// Create an instance with `locale`.
  public init(locale: Locale) {
    func __cldrLocaleIdentifier() -> String {
      #if canImport(Darwin)
      if #available(iOS 16, macOS 13, macCatalyst 16, tvOS 16, watchOS 9, visionOS 1, *) {
        return locale.identifier(.cldr)
      }
      #endif
      return String(Locale.canonicalLanguageIdentifier(from: locale.identifier).map({
        switch $0 {
        case "-": return "_" as Character
        default: return $0
        }
      }))
    }
    self.init(name: SQLIdentifierConvertibleString(__cldrLocaleIdentifier(), caseSensitive: true))
  }
}

/// A type name defined by a user, for example, in `CREATE TYPE`.
public struct TypeName: SchemaQualifiedIdentifier {
  public var schema: SQLIdentifierConvertibleString?

  public var name: SQLIdentifierConvertibleString

  public init(schema: SQLIdentifierConvertibleString? = nil, name: SQLIdentifierConvertibleString) {
    self.schema = schema
    self.name = name
  }
}
