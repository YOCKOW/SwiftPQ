/* *************************************************************************************************
 TableElement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element to define column(s). This is described as `TableElement` in "gram.y".
public struct TableElement: SQLTokenSequence {
  public enum Clause: SQLTokenSequence {
    case columnDefinition(ColumnDefinition)
    case tableLikeClause(TableLikeClause)
    case tableConstraint(TableConstraint)

    @inlinable
    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .columnDefinition(let columnDefinition):
        return columnDefinition.tokens
      case .tableLikeClause(let tableLikeClause):
        return tableLikeClause.tokens
      case .tableConstraint(let tableConstraint):
        return tableConstraint.tokens
      }
    }
  }

  public let clause: Clause

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    return clause.tokens
  }

  @inlinable
  public init(_ columnDefinition: ColumnDefinition) {
    self.clause = .columnDefinition(columnDefinition)
  }

  @inlinable
  public init(_ tableLikeClause: TableLikeClause) {
    self.clause = .tableLikeClause(tableLikeClause)
  }

  @inlinable
  public init(_ tableConstraint: TableConstraint) {
    self.clause = .tableConstraint(tableConstraint)
  }

  @inlinable
  public static func columnDefinition(_ columnDefinition: ColumnDefinition) -> TableElement {
    return .init(columnDefinition)
  }

  /// Returns column definition created with the given parameters.
  @inlinable
  public static func column(
    name: ColumnIdentifier,
    dataType: TypeName,
    storageMode: ColumnStorageMode? = nil,
    compressionMode: ColumnCompressionMode? = nil,
    genericOptions: GenericOptionsClause? = nil,
    qualifiers: ColumnQualifierList? = nil
  ) -> TableElement {
    return .columnDefinition(
      ColumnDefinition(
        name: name,
        dataType: dataType,
        storageMode: storageMode,
        compressionMode: compressionMode,
        genericOptions: genericOptions,
        qualifiers: qualifiers
      )
    )
  }


  @inlinable
  public static func tableLikeClause(_ tableLikeClause: TableLikeClause) -> TableElement {
    return .init(tableLikeClause)
  }

  @inlinable
  public static func like(
    _ sourceTable: TableName,
    options: TableLikeOptionList? = nil
  ) -> TableElement {
    return .tableLikeClause(TableLikeClause(like: sourceTable, options: options))
  }

  @inlinable
  public static func tableConstraint(_ tableConstraint: TableConstraint) -> TableElement {
    return .init(tableConstraint)
  }

  @inlinable
  public static func constraint(
    name: Name? = nil,
    _ constraint: TableConstraintElement
  ) -> TableElement {
    return .tableConstraint(TableConstraint(name: name, constraint: constraint))
  }
}

/// A type that can be a `TableElement`.
public protocol TableElementConvertible: SQLTokenSequence {
  var tableElement: TableElement { get }
}
extension ColumnDefinition: TableElementConvertible {
  @inlinable
  public var tableElement: TableElement { return .init(self) }
}
extension TableLikeClause: TableElementConvertible {
  @inlinable
  public var tableElement: TableElement { return .init(self) }
}
extension TableConstraint: TableElementConvertible {
  @inlinable
  public var tableElement: TableElement { return .init(self) }
}

/// An element to define column(s). This is described as `TypedTableElement` in "gram.y".
public struct TypedTableElement: SQLTokenSequence {
  public enum Clause: SQLTokenSequence {
    case columnDefinition(TypedTableColumnDefinition)
    case tableConstraint(TableConstraint)

    @inlinable
    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .columnDefinition(let columnDefinition):
        return columnDefinition.tokens
      case .tableConstraint(let tableConstraint):
        return tableConstraint.tokens
      }
    }
  }

  public let clause: Clause

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    return clause.tokens
  }

  @inlinable
  public init(_ columnDefinition: TypedTableColumnDefinition) {
    self.clause = .columnDefinition(columnDefinition)
  }

  @inlinable
  public init(_ tableConstraint: TableConstraint) {
    self.clause = .tableConstraint(tableConstraint)
  }

  @inlinable
  public static func columnDefinition(_ columnDefinition: ColumnDefinition) -> TableElement {
    return .init(columnDefinition)
  }

  /// Returns column definition created with the given parameters.
  @inlinable
  public static func column(
    name: ColumnIdentifier,
    dataType: TypeName,
    storageMode: ColumnStorageMode? = nil,
    compressionMode: ColumnCompressionMode? = nil,
    genericOptions: GenericOptionsClause? = nil,
    qualifiers: ColumnQualifierList? = nil
  ) -> TableElement {
    return .columnDefinition(
      ColumnDefinition(
        name: name,
        dataType: dataType,
        storageMode: storageMode,
        compressionMode: compressionMode,
        genericOptions: genericOptions,
        qualifiers: qualifiers
      )
    )
  }

  @inlinable
  public static func tableConstraint(_ tableConstraint: TableConstraint) -> TableElement {
    return .init(tableConstraint)
  }

  @inlinable
  public static func constraint(
    name: Name? = nil,
    _ constraint: TableConstraintElement
  ) -> TableElement {
    return .tableConstraint(TableConstraint(name: name, constraint: constraint))
  }
}

/// A type that can be a `TypedTableElement`.
public protocol TypedTableElementConvertible: SQLTokenSequence {
  var typedTableElement: TypedTableElement { get }
}
extension TypedTableColumnDefinition: TypedTableElementConvertible {
  @inlinable
  public var typedTableElement: TypedTableElement { return .init(self) }
}
extension TableConstraint: TypedTableElementConvertible {
  @inlinable
  public var typedTableElement: TypedTableElement { return .init(self) }
}


/// A list of `TableElement`s. This is described as `TableElementList` in "gram.y".
public struct TableElementList: SQLTokenSequence,
                                InitializableWithNonEmptyList,
                                ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = TableElement
  public typealias ArrayLiteralElement = TableElement

  public var elements: NonEmptyList<TableElement>

  public var tokens: JoinedSQLTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<TableElement>) {
    self.elements = elements
  }

  @inlinable
  public init(_ convertibles: NonEmptyList<any TableElementConvertible>) {
    self.elements = convertibles.map(\.tableElement)
  }
}

/// A list of `TypedTableElement`s. This is described as `TypedTableElementList` in "gram.y".
public struct TypedTableElementList: SQLTokenSequence,
                                     InitializableWithNonEmptyList,
                                     ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = TypedTableElement
  public typealias ArrayLiteralElement = TypedTableElement

  public var elements: NonEmptyList<TypedTableElement>

  public var tokens: JoinedSQLTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<TypedTableElement>) {
    self.elements = elements
  }

  @inlinable
  public init(_ convertibles: NonEmptyList<any TypedTableElementConvertible>) {
    self.elements = convertibles.map(\.typedTableElement)
  }
}


/// Representation of `OptTypedTableElementList` in "gram.y".
///
/// This should not be represented by `Optional<TypedTableElementList>`
/// because `OptTypedTableElementList` must emit parenthesized `TypedTableElementList` if it has a value.
public enum OptionalTypedTableElementList: SQLTokenSequence,
                                           InitializableWithNonEmptyList,
                                           ExpressibleByNilLiteral,
                                           ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = TypedTableElement
  public typealias ArrayLiteralElement = TypedTableElement

  case none
  case some(TypedTableElementList)

  public struct Iterator: IteratorProtocol {
   public typealias Element = SQLToken
   private var _iterator: Parenthesized<TypedTableElementList>.Iterator?
   fileprivate init(_ iterator: Parenthesized<TypedTableElementList>.Iterator?) {
     self._iterator = iterator
   }
   public mutating func next() -> SQLToken? { return _iterator?.next() }
  }

  public typealias Tokens = Self

  public func makeIterator() -> Iterator {
   guard case .some(let list) = self else { return Iterator(nil) }
   return Iterator(list.parenthesized.makeIterator())
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
  public var typedTableElementList: TypedTableElementList? {
   guard case .some(let list) = self else { return nil }
   return list
  }

  @inlinable
  public init(nilLiteral: ()) {
   self = .none
  }

  @inlinable
  public init(_ list: NonEmptyList<TypedTableElement>) {
   self = .some(TypedTableElementList(list))
  }

  @inlinable
  public init(_ list: NonEmptyList<any TypedTableElementConvertible>) {
   self = .some(TypedTableElementList(list))
  }
}
