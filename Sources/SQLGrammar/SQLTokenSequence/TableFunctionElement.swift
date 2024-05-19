/* *************************************************************************************************
 TableFunctionElement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element that is described as `TableFuncElement` in "gram.y".
public struct TableFunctionElement: SQLTokenSequence {
  public let column: ColumnIdentifier

  public let type: TypeName

  public let collation: CollateClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(column.asSequence, type, collation)
  }

  public init(column: ColumnIdentifier, type: TypeName, collation: CollateClause? = nil) {
    self.column = column
    self.type = type
    self.collation = collation
  }
}

/// A list of `TableFunctionElement`s that is described as `TableFuncElementList` in "gram.y".
public struct TableFunctionElementList: SQLTokenSequence, ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = TableFunctionElement

  public let elements: NonEmptyList<TableFunctionElement>

  public var tokens: JoinedSQLTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<TableFunctionElement>) {
    self.elements = elements
  }

  public init(arrayLiteral elements: TableFunctionElement...) {
    guard let nonEmptyElements = NonEmptyList<TableFunctionElement>(items: elements) else {
      fatalError("No elements?!")
    }
    self.init(nonEmptyElements)
  }
}
