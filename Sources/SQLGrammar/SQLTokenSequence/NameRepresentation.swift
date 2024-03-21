/* *************************************************************************************************
 NameRepresentation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that represents a kind of name.
public protocol NameRepresentation: SQLTokenSequence {}

/// A type representing a name that is described as `any_name` in "gram.y".
public protocol AnyName: NameRepresentation {
  var identifier: ColumnIdentifier { get }
  var attributes: AttributeList? { get }
}
extension  AnyName where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    // Note: `Attributes` include leading period!
    return JoinedSQLTokenSequence.compacting(SingleToken(identifier), attributes)
  }
}

/// A qualified name that is described as `qualified_name` in "gram.y".
public protocol QualifiedName: NameRepresentation {
  var identifier: ColumnIdentifier { get }
  var indirection: Indirection? { get }
}
extension QualifiedName where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(SingleToken(identifier), indirection)
  }
}

extension QualifiedName where Self: AnyName {
  public var indirection: Indirection? {
    guard let attributes else { return nil }
    let elements = attributes.names.map({ Indirection.List.Element.attributeName($0) })
    return Indirection(Indirection.List(elements))
  }
}

extension QualifiedName where Self: AnyName, Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(SingleToken(identifier), attributes)
  }
}


// MARK: - Detail Implementations

/// A type representing a name of database.
/// No corresponding expression exists in "gram.y",
/// but almost same with the word described as `database_name` in [official documentation](https://www.postgresql.org/docs).
public struct DatabaseName: NameRepresentation {
  public typealias Elment = SQLToken
  public typealias Tokens = Self
  public typealias Iterator = SingleToken.Iterator

  public let identifier: ColumnIdentifier

  public init(_ identifier: ColumnIdentifier) {
    self.identifier = identifier
  }

  public init(_ name: String) {
    self.init(ColumnIdentifier(name))
  }

  public func makeIterator() -> Iterator {
    return SingleToken.Iterator(identifier.token)
  }
}

/// A type representing a function name that is described as `func_name` in "gram.y".
public struct FunctionName: NameRepresentation {
  /// An identifier that can be a function name.
  public struct Identifier: LosslessTokenConvertible {
    private let _name: TypeOrFunctionName

    public var token: SQLToken { return _name.token }

    public init?(_ token: SQLToken) {
      guard let name = TypeOrFunctionName(token) else { return nil }
      self._name = name
    }
  }

  private enum _Type {
    case identifier(Identifier)
    case qualifiedName(any QualifiedName)
  }

  private let _type: _Type

  public struct Tokens: Sequence {
    public typealias Element = SQLToken

    private let _name: FunctionName

    fileprivate init(_ name: FunctionName) {
      self._name = name
    }

    public struct Iterator: IteratorProtocol {
      private var _iterator: AnySQLTokenSequenceIterator

      fileprivate init<S>(_ seq: S) where S: Sequence, S.Element: SQLToken {
        self._iterator = AnySQLTokenSequenceIterator(seq)
      }

      public func next() -> Element? {
        return _iterator.next()
      }
    }

    public func makeIterator() -> Iterator {
      switch _name._type {
      case .identifier(let identifier):
        return .init(SingleToken(identifier))
      case .qualifiedName(let qualifiedName):
        return .init(qualifiedName)
      }
    }
  }

  public var tokens: Tokens {
    return .init(self)
  }

  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }

  /// Creates a name with given token. Returns `nil` if invalid token was given.
  public init?(_ token: SQLToken) {
    guard let identifier = Identifier(token) else { return nil }
    self._type = .identifier(identifier)
  }

  public init(_ string: String) {
    guard let instance = Self.init(.identifier(string)) else {
      fatalError("Failed to create an identifier?!")
    }
    self = instance
  }

  public init<Q>(_ otherName: Q) where Q: QualifiedName {
    self._type = .qualifiedName(otherName)
  }

  /// Returns an instance of `TypeName` with the same name.
  public var asTypeName: TypeName {
    return .init(self)
  }
}

/// A type representing a name which is described as `object_type_any_name` in "gram.y".
public enum ObjectTypeAnyName: NameRepresentation {
  case table
  case sequence
  case view
  case materializedView
  case index
  case foreignTable
  case collation
  case conversion
  case statistics
  case textSearchParser
  case textSearchDictionary
  case textSearchTemplate
  case textSearchConfiguration

  public var tokens: Array<SQLToken> {
    switch self {
    case .table:
      return [.table]
    case .sequence:
      return [.sequence]
    case .view:
      return [.view]
    case .materializedView:
      return [.materialized, .view]
    case .index:
      return [.index]
    case .foreignTable:
      return [.foreign, .table]
    case .collation:
      return [.collation]
    case .conversion:
      return [.conversion]
    case .statistics:
      return [.statistics]
    case .textSearchParser:
      return [.text, .search, .parser]
    case .textSearchDictionary:
      return [.text, .search, .dictionary]
    case .textSearchTemplate:
      return [.text, .search, .template]
    case .textSearchConfiguration:
      return [.text, .search, .configuration]
    }
  }
}

/// A name for parameter, that is described as `param_name` in "gram.y".
public struct ParameterName: NameRepresentation,
                             LosslessTokenConvertible,
                             ExpressibleByStringLiteral {
  private let _name: TypeOrFunctionName

  public var token: SQLToken {
    return _name.token
  }

  public var tokens: SingleToken {
    return .init(_name.token)
  }

  public func makeIterator() -> SingleToken.Iterator {
    return tokens.makeIterator()
  }

  public init?(_ token: SQLToken) {
    guard let name = TypeOrFunctionName(token) else { return nil }
    self._name = name
  }

  public init(stringLiteral value: String) {
    self.init(.identifier(value))!
  }
}

/// A type representing a name of schema.
public struct SchemaName: ExpressibleByStringLiteral, NameRepresentation {
  public typealias StringLiteralType = String
  public typealias Elment = SQLToken
  public typealias Tokens = Self
  public typealias Iterator = SingleToken.Iterator

  public let identifier: ColumnIdentifier

  public init(_ identifier: ColumnIdentifier) {
    self.identifier = identifier
  }

  public init(_ name: String) {
    self.init(ColumnIdentifier(name))
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }

  public func makeIterator() -> Iterator {
    return SingleToken.Iterator(identifier.token)
  }
}

/// A type representing a name of a table.
public struct TableName: ExpressibleByStringLiteral, AnyName, QualifiedName {
  public typealias StringLiteralType = String

  public let database: DatabaseName?

  public let schema: SchemaName?

  public let name: String

  public var identifier: ColumnIdentifier {
    switch (database, schema) {
    case (nil, nil):
      return ColumnIdentifier(name)
    case (nil, let schema?):
      return schema.identifier
    case (let database?, _?):
      return database.identifier
    default:
      fatalError("Unexpected combination of properties?!")
    }
  }

  public var attributes: AttributeList? {
    switch (database, schema) {
    case (nil, nil):
      return nil
    case (nil, _?):
      return [.columnLabel(ColumnLabel(name))]
    case (_?, let schema?):
      let schemaLabel = ColumnLabel(schema.identifier.token) ?? ColumnLabel(schema.identifier.token._rawValue)
      return [
        .columnLabel(schemaLabel),
        .columnLabel(ColumnLabel(name)),
      ]
    default:
      fatalError("Unexpected combination of properties?!")
    }
  }

  public init(database: DatabaseName, schema: SchemaName, name: String) {
    self.database = database
    self.schema = schema
    self.name = name
  }

  public init(schema: SchemaName, name: String) {
    self.database = nil
    self.schema = schema
    self.name = name
  }

  public init(name: String) {
    self.database = nil
    self.schema = nil
    self.name = name
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }
}

/// A name of a type.
///
/// There is no corresponding value in "gram.y" because it is the same with `func_name`.
/// In this module, this type exists to distinguish a name of type from one of function.
public struct TypeName: NameRepresentation {
  public typealias Element = SQLToken

  private let _name: FunctionName

  public struct Iterator: IteratorProtocol {
    private var _iterator: FunctionName.Iterator
    fileprivate init(_ iterator: FunctionName.Iterator) { self._iterator = iterator }
    public mutating func next() -> SQLToken? {
      return _iterator.next()
    }
  }

  public func makeIterator() -> Iterator {
    return .init(_name.makeIterator())
  }

  /// Returns an instance of `FunctionName` with the same name.
  public var asFunctionName: FunctionName {
    return _name
  }

  fileprivate init(_ name: FunctionName) {
    self._name = name
  }

  /// Creates a name with given token. Returns `nil` if invalid token was given.
  public init?(_ token: SQLToken) {
    guard let name = FunctionName(token) else { return nil }
    self.init(name)
  }

  public init(_ string: String) {
    guard let instance = Self.init(.identifier(string)) else {
      fatalError("Failed to create an identifier?!")
    }
    self = instance
  }

  public init<Q>(_ otherName: Q) where Q: QualifiedName {
    self._name = FunctionName(otherName)
  }
}
