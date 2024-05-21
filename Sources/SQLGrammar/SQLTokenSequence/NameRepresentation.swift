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

private struct _DatabaseSchemaQualifiedName {
  let database: DatabaseName?

  let schema: SchemaName?

  let name: SQLToken.Identifier

  var nameAsColumnIdentifier: ColumnIdentifier { ColumnIdentifier(name)! }

  var nameAsColumnLabel: ColumnLabel { ColumnLabel(name)! }

  var identifier: ColumnIdentifier {
    switch (database, schema) {
    case (nil, nil):
      return nameAsColumnIdentifier
    case (nil, let schema?):
      return schema.identifier
    case (let database?, _?):
      return database.identifier
    default:
      fatalError("Unexpected combination of properties?!")
    }
  }

  var attributes: AttributeList? {
    switch (database, schema) {
    case (nil, nil):
      return nil
    case (nil, _?):
      return [.columnLabel(nameAsColumnLabel)]
    case (_?, let schema?):
      let schemaLabel = ColumnLabel(schema.identifier.token) ?? ColumnLabel(schema.identifier.token._rawValue)
      return [
        .columnLabel(schemaLabel),
        .columnLabel(nameAsColumnLabel),
      ]
    default:
      fatalError("Unexpected combination of properties?!")
    }
  }

  init(database: DatabaseName, schema: SchemaName, name: SQLToken.Identifier) {
    self.database = database
    self.schema = schema
    self.name = name
  }

  init(schema: SchemaName, name: SQLToken.Identifier) {
    self.database = nil
    self.schema = schema
    self.name = name
  }

  init(name: SQLToken.Identifier) {
    self.database = nil
    self.schema = nil
    self.name = name
  }
}

// MARK: - Detail Implementations

public struct CollationName: AnyName {
  public typealias StringLiteralType = String

  private let _name: _DatabaseSchemaQualifiedName

  public var database: DatabaseName? { _name.database }

  public var schema: SchemaName? { _name.schema }

  public var name: SQLToken.Identifier { _name.name }

  public var identifier: ColumnIdentifier { _name.identifier }

  public var attributes: AttributeList? { _name.attributes }

  public init(
    database: DatabaseName,
    schema: SchemaName,
    name: String,
    caseSensitive: Bool = false
  ) {
    self._name = .init(
      database: database,
      schema: schema,
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(
    schema: SchemaName,
    name: String,
    caseSensitive: Bool = false
  ) {
    self._name = .init(
      schema: schema,
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(name: String, caseSensitive: Bool = false) {
    self._name = .init(
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }

  public static let c: CollationName = .init(name: "C", caseSensitive: true)
}

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
public struct FunctionName: NameRepresentation, ExpressibleByStringLiteral {
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

  public init(stringLiteral value: String) {
    guard let instance = Self.init(.identifier(value)) else {
      fatalError("Failed to create an identifier?!")
    }
    self = instance
  }

  public init<Q>(_ otherName: Q) where Q: QualifiedName {
    self._type = .qualifiedName(otherName)
  }
}

/// Representation of `name` in "gram.y".
public struct Name: NameRepresentation {
  public let identifier: ColumnIdentifier

  public var tokens: SingleToken {
    return SingleToken(identifier)
  }

  public func makeIterator() -> SingleTokenIterator<SQLToken> {
    return tokens.makeIterator()
  }

  public init(_ identifier: ColumnIdentifier) {
    self.identifier = identifier
  }
}

extension ColumnIdentifier {
  public var asName: Name { Name(self) }
}

/// Representation of `name_list` in "gram.y".
public struct NameList: SQLTokenSequence, ExpressibleByArrayLiteral {
  public let names: NonEmptyList<Name>

  public var tokens: JoinedSQLTokenSequence {
    return names.joinedByCommas()
  }

  public init(_ names: NonEmptyList<Name>) {
    self.names = names
  }
  
  public init(arrayLiteral elements: Name...) {
    guard let nonEmptyNames = NonEmptyList(items: elements) else {
      fatalError("\(Self.self): No names?!")
    }
    self.init(nonEmptyNames)
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

  private let _name: _DatabaseSchemaQualifiedName

  public var database: DatabaseName? { _name.database }

  public var schema: SchemaName? { _name.schema }

  public var name: SQLToken.Identifier { _name.name }

  public var identifier: ColumnIdentifier { _name.identifier }

  public var attributes: AttributeList? { _name.attributes }

  public init(
    database: DatabaseName,
    schema: SchemaName,
    name: String,
    caseSensitive: Bool = false
  ) {
    self._name = .init(
      database: database,
      schema: schema,
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(
    schema: SchemaName,
    name: String,
    caseSensitive: Bool = false
  ) {
    self._name = .init(
      schema: schema,
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(name: String, caseSensitive: Bool = false) {
    self._name = .init(
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }
}

/// A name of a temporary table, that is described as `OptTempTableName` in "gram.y".
public struct TemporaryTableName: NameRepresentation {
  public enum TemporarinessType: Segment {
    /// `LOCAL TEMPORARY`
    case localTempoary

    /// `GLOBAL TEMPORARY`
    case globalTemporary

    /// `LOCAL TEMP`
    case localTemp

    /// `GLOBAL TEMP`
    case globalTemp

    /// `TEMPORARY`
    case temporary

    /// `TMP`
    case temp

    /// `UNLOGGED`
    case unlogged

    @inlinable
    public var tokens: Array<SQLToken> {
      switch self {
      case .localTempoary:
        return [.local, .temporary]
      case .globalTemporary:
        return [.global, .temporary]
      case .localTemp:
        return [.local, .temp]
      case .globalTemp:
        return [.global, .temp]
      case .temporary:
        return [.temporary]
      case .temp:
        return [.temp]
      case .unlogged:
        return [.unlogged]
      }
    }
  }

  public let prefix: TemporarinessType?

  public var omitTableToken: Bool = false

  public let name: TableName

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(
      prefix,
      omitTableToken ? nil : SingleToken(.table),
      name
    )
  }

  public init(_ prefix: TemporarinessType? = .temporary, table name: TableName) {
    self.prefix = prefix
    self.name = name
  }
}
