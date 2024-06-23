/* *************************************************************************************************
 FunctionType.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A column reference for "[copying types](https://www.postgresql.org/docs/current/plpgsql-declarations.html#PLPGSQL-DECLARATION-TYPE)".
///
/// This is representation of `type_function_name attrs`.
public struct CopyingTypeColumnReference: SQLTokenSequence {
  private let _top: TypeOrFunctionName

  private let _rest: AttributeList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(_top.asSequence, _rest)
  }

  public init?(table: TableName, column: ColumnReference) {
    guard let top = TypeOrFunctionName(table.identifier.token) else { return nil }
    
    var attributes: [AttributeName] = table.attributes?.names.items ?? []
    
    guard let columnLabel = ColumnLabel(column.identifier.token) else { return nil }
    attributes.append(.columnLabel(columnLabel))

    if let indirection = column.indirection {
      for elem in indirection.list {
        guard case .attributeName(let name) = elem else { return nil }
        attributes.append(name)
      }
    }

    self._top = top
    self._rest = AttributeList(names: NonEmptyList(items: attributes)!)
  }

  public init?(column: ColumnReference) {
    guard let top = TypeOrFunctionName(column.identifier.token) else { return nil }
    guard let indirection = column.indirection else { return nil }
    var attributes: [AttributeName] = []
    for elem in indirection.list {
      guard case .attributeName(let name) = elem else { return nil }
      attributes.append(name)
    }
    self._top = top
    self._rest = AttributeList(names: NonEmptyList(items: attributes)!)
  }
}

/// A declaration of a type that is described as `func_type` in "gram.y".
public struct FunctionType: SQLTokenSequence {
  private enum _Type {
    case typeName(TypeName)
    case copyingType(isSet: Bool, CopyingTypeColumnReference)
  }

  private let _type: _Type

  public var tokens: JoinedSQLTokenSequence {
    switch _type {
    case .typeName(let typeName):
      return typeName.tokens
    case .copyingType(let isSet, let ref):
      return .compacting(
        isSet ? SingleToken(.setof) : nil,
        ref,
        SingleToken.joiner,
        SingleToken(try! SQLToken.Operator("%")),
        SingleToken.joiner,
        SingleToken(.type)
      )
    }
  }

  public init(_ typeName: TypeName) {
    self._type = .typeName(typeName)
  }

  public init(isSet: Bool = false, copyingType: CopyingTypeColumnReference) {
    self._type = .copyingType(isSet: isSet, copyingType)
  }
}
