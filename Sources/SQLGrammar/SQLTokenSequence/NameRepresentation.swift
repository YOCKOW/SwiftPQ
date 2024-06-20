/* *************************************************************************************************
 NameRepresentation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

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

/// Internal representation of `QualifiedName` that must not be `public`.
internal struct AnyQualifiedName: QualifiedName {
  let identifier: ColumnIdentifier
  let indirection: Indirection?

  init(identifier: ColumnIdentifier, indirection: Indirection? = nil) {
    self.identifier = identifier
    self.indirection = indirection
  }

  init<OtherName>(_ otherName: OtherName) where OtherName: QualifiedName {
    self.init(identifier: otherName.identifier, indirection: otherName.indirection)
  }
}

internal protocol _PossiblyQualifiedNameConvertible {
  associatedtype _QualifiedName: QualifiedName
  var _qualifiedName: Optional<_QualifiedName> { get }
}

struct _DatabaseSchemaQualifiedName: AnyName, QualifiedName {
  let database: DatabaseName?

  let schema: SchemaName?

  let name: SQLToken.Identifier

  @inlinable
  var nameAsColumnIdentifier: ColumnIdentifier { ColumnIdentifier(name)! }

  @inlinable
  var nameAsColumnLabel: ColumnLabel { ColumnLabel(name)! }

  @inlinable
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

  @inlinable
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

  @inlinable
  init(database: DatabaseName, schema: SchemaName, name: SQLToken.Identifier) {
    self.database = database
    self.schema = schema
    self.name = name
  }

  @inlinable
  init(schema: SchemaName, name: SQLToken.Identifier) {
    self.database = nil
    self.schema = schema
    self.name = name
  }

  @inlinable
  init(name: SQLToken.Identifier) {
    self.database = nil
    self.schema = nil
    self.name = name
  }
}

protocol _DatabaseSchemaQualifiedNameConvertible {
  var _databaseSchemaQualifiedName: _DatabaseSchemaQualifiedName { get }
}

extension _DatabaseSchemaQualifiedName {
  private init(_selfTypeName: _DatabaseSchemaQualifiedName) {
    self = _selfTypeName
  }

  private init(_convertibleTypeName: any _DatabaseSchemaQualifiedNameConvertible) {
    self = _convertibleTypeName._databaseSchemaQualifiedName
  }

  private init?(_identifier: ColumnIdentifier, attributes: AttributeList?) {
    guard let attributes = attributes else {
      guard case let name as SQLToken.Identifier = _identifier.token else {
        return nil
      }
      self.init(name: name)
      return
    }
    
    switch attributes.names.count {
    case 1:
      guard case .columnLabel(let columnLabel) = attributes.names.first,
            case let name as SQLToken.Identifier = columnLabel.token else {
        return nil
      }
      self.init(schema: SchemaName(_identifier), name: name)
    case 2:
      guard case .columnLabel(let schemaAsColumnLabel) = attributes.names.first,
            case .columnLabel(let nameAsColumnLabel) = attributes.names.last,
            let schemaAsColId = ColumnIdentifier(schemaAsColumnLabel.token),
            case let name as SQLToken.Identifier = nameAsColumnLabel.token else {
        return nil
      }
      self.init(
        database: DatabaseName(_identifier),
        schema: SchemaName(schemaAsColId),
        name: name
      )
    default:
      return nil
    }
  }

  @inlinable
  init?<OtherName>(_ otherName: OtherName) where OtherName: AnyName {
    switch otherName {
    case let selfTypeName as _DatabaseSchemaQualifiedName:
      self.init(_selfTypeName: selfTypeName)
    case let convertibleTypeName as any _DatabaseSchemaQualifiedNameConvertible:
      self.init(_convertibleTypeName: convertibleTypeName)
    default:
      self.init(_identifier: otherName.identifier, attributes: otherName.attributes)
    }
  }

  private enum __Error: Error { case conversionFailure }

  @inlinable
  init?<OtherName>(_ otherName: OtherName) where OtherName: QualifiedName {
    switch otherName {
    case let selfTypeName as _DatabaseSchemaQualifiedName:
      self.init(_selfTypeName: selfTypeName)
    case let convertibleTypeName as any _DatabaseSchemaQualifiedNameConvertible:
      self.init(_convertibleTypeName: convertibleTypeName)
    default:
      do {
        let attributeNames = try otherName.indirection?.list.map({
          guard case .attributeName(let attrName) = $0 else {
            throw __Error.conversionFailure
          }
          return attrName
        })
        self.init(
          _identifier: otherName.identifier,
          attributes: attributeNames.map(AttributeList.init(names:))
        )
      } catch {
        return nil
      }
    }
  }
}

// MARK: - Detail Implementations

public struct CollationName: AnyName, _DatabaseSchemaQualifiedNameConvertible {
  public typealias StringLiteralType = String

  let _databaseSchemaQualifiedName: _DatabaseSchemaQualifiedName

  public var database: DatabaseName? { _databaseSchemaQualifiedName.database }

  public var schema: SchemaName? { _databaseSchemaQualifiedName.schema }

  public var name: SQLToken.Identifier { _databaseSchemaQualifiedName.name }

  public var identifier: ColumnIdentifier { _databaseSchemaQualifiedName.identifier }

  public var attributes: AttributeList? { _databaseSchemaQualifiedName.attributes }

  public init(
    database: DatabaseName,
    schema: SchemaName,
    name: String,
    caseSensitive: Bool = false
  ) {
    self._databaseSchemaQualifiedName = .init(
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
    self._databaseSchemaQualifiedName = .init(
      schema: schema,
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(name: String, caseSensitive: Bool = false) {
    self._databaseSchemaQualifiedName = .init(
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  @inlinable
  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }

  /// Creates an instance with `locale`.
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
    self.init(name: __cldrLocaleIdentifier(), caseSensitive: true)
  }

  /// Creates an instance with `locale`.
  public static func locale(_ locale: Locale) -> CollationName {
    return CollationName(locale: locale)
  }

  public static let c: CollationName = .init(name: "C", caseSensitive: true)

  /// Use POSIX locale for collation.
  public static let posix: CollationName = .init(name: "POSIX", caseSensitive: true)

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

  /// Convert `typeName` to a instance of `FunctionName` if possible.
  public init?(_ typeName: TypeName) {
    guard let qualifiedName = typeName._qualifiedName else { return nil }
    self._type = .qualifiedName(qualifiedName)
  }
}

/// Representation of `name` in "gram.y".
public struct Name: NameRepresentation, ExpressibleByStringLiteral {
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

  public init(stringLiteral value: String) {
    self.identifier = ColumnIdentifier(stringLiteral: value)
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

/// A name used in `part_elem`. This is described as `opclass` in
/// [official documentation](https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-PARMS-PARTITION-BY).
public struct OperatorClass: AnyName {
  public let identifier: ColumnIdentifier

  public let attributes: AttributeList?

  public init(identifier: ColumnIdentifier, attributes: AttributeList? = nil) {
    self.identifier = identifier
    self.attributes = attributes
  }
}

/// Representation of `opt_name_list` in "gram.y".
///
/// This should not be represented by `Optional<NameList>`
/// because `opt_name_list` must emit parenthesized `name_list` if it has a value.
public enum OptionalNameList: SQLTokenSequence,
                              ExpressibleByNilLiteral,
                              ExpressibleByArrayLiteral {
  case none
  case some(NameList)

  public struct Tokens: Sequence {
    public typealias Element = SQLToken

    private let _list: OptionalNameList

    fileprivate init(_ list: OptionalNameList) {
      self._list = list
    }

    public struct Iterator: IteratorProtocol {
      public typealias Element = SQLToken

      private let _iterator: AnySQLTokenSequenceIterator?

      public mutating func next() -> Element? {
        return _iterator?.next()
      }

      fileprivate init(_ iterator: AnySQLTokenSequenceIterator?) {
        self._iterator = iterator
      }
    }

    public func makeIterator() -> Iterator {
      switch _list {
      case .none:
        return Iterator(nil)
      case .some(let list):
        return Iterator(AnySQLTokenSequenceIterator(list.parenthesized))
      }
    }
  }

  @inlinable
  public var isNil: Bool {
    switch self {
    case .none:
      return true
    case .some:
      return false
    }
  }

  @inlinable
  public var nameList: NameList? {
    guard case .some(let list) = self else { return nil }
    return list
  }

  @inlinable
  public func map<T>(_ transform: (NameList) throws -> T) rethrows -> T? {
    return try nameList.map(transform)
  }

  @inlinable
  public func flatMap<T>(_ transform: (NameList) throws -> T?) rethrows -> T? {
    return try nameList.flatMap(transform)
  }

  public var tokens: Tokens {
    return Tokens(self)
  }

  @inlinable
  public func tokensMap<T>(_ transform: (OptionalNameList.Tokens) throws -> T) rethrows -> T? {
    switch self {
    case .none:
      return nil
    case .some:
      return try transform(tokens)
    }
  }

  @inlinable
  public func tokensFlatMap<T>(_ transform: (OptionalNameList.Tokens) throws -> T?) rethrows -> T? {
    switch self {
    case .none:
      return nil
    case .some:
      return try transform(tokens)
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }

  @inlinable
  public init(nilLiteral: ()) {
    self = .none
  }

  @inlinable
  public init(arrayLiteral elements: Name...) {
    guard let nonEmptyNames = NonEmptyList(items: elements) else {
      fatalError("\(Self.self): No names?!")
    }
    self = .some(NameList(nonEmptyNames))
  }

  @inlinable
  public init(_ optional: Optional<NameList>) {
    switch optional {
    case .none:
      self = .none
    case .some(let list):
      self = .some(list)
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

/// A list of qualified names. Described as `qualified_name_list` in "gram.y".
public struct QualifiedNameList<Q>: SQLTokenSequence,
                                    InitializableWithNonEmptyList,
                                    ExpressibleByArrayLiteral where Q: QualifiedName {
  public let names: NonEmptyList<Q>

  public var tokens: JoinedSQLTokenSequence {
    return names.joinedByCommas()
  }

  public init(_ names: NonEmptyList<Q>) {
    self.names = names
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
public struct TableName: ExpressibleByStringLiteral,
                         AnyName,
                         QualifiedName,
                         _DatabaseSchemaQualifiedNameConvertible {
  public typealias StringLiteralType = String

  let _databaseSchemaQualifiedName: _DatabaseSchemaQualifiedName

  public var database: DatabaseName? { _databaseSchemaQualifiedName.database }

  public var schema: SchemaName? { _databaseSchemaQualifiedName.schema }

  public var name: SQLToken.Identifier { _databaseSchemaQualifiedName.name }

  public var identifier: ColumnIdentifier { _databaseSchemaQualifiedName.identifier }

  public var attributes: AttributeList? { _databaseSchemaQualifiedName.attributes }

  public init(
    database: DatabaseName,
    schema: SchemaName,
    name: String,
    caseSensitive: Bool = false
  ) {
    self._databaseSchemaQualifiedName = .init(
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
    self._databaseSchemaQualifiedName = .init(
      schema: schema,
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(name: String, caseSensitive: Bool = false) {
    self._databaseSchemaQualifiedName = .init(
      name: SQLToken.identifier(name, forceQuoting: caseSensitive) as! SQLToken.Identifier
    )
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }

  public init?<OtherName>(_ otherName: OtherName) where OtherName: QualifiedName {
    switch otherName {
    case let tableName as TableName:
      self = tableName
    default:
      guard let name = _DatabaseSchemaQualifiedName(otherName) else {
        return nil
      }
      self._databaseSchemaQualifiedName = name
    }
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
