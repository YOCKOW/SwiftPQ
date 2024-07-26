/* *************************************************************************************************
 FromClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A list, that is described as `from_list`, used in `FROM` clause.
public struct FromList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public let tableReferences: NonEmptyList<any TableReferenceExpression>

  public var tokens: JoinedSQLTokenSequence {
    return tableReferences.map({ $0 as any TokenSequenceGenerator }).joinedByCommas()
  }

  public init(tableReferences: NonEmptyList<any TableReferenceExpression>) {
    self.tableReferences = tableReferences
  }

  public init(arrayLiteral elements: (any TableReferenceExpression)...) {
    guard let nonEmptyExprs = NonEmptyList<any TableReferenceExpression>(items: elements) else {
      fatalError("\(Self.self): No references?!")
    }
    self.init(tableReferences: nonEmptyExprs)
  }

  public init<each Expr>(
    _ firstTableReference: any TableReferenceExpression,
    _ optionalTableReference: repeat each Expr
  ) where repeat each Expr: TableReferenceExpression {
    var references: [any TableReferenceExpression] = [firstTableReference]
    repeat (references.append(each optionalTableReference))
    self.init(tableReferences: NonEmptyList(items: references)!)
  }
}

/// A `FROM` clause that is described as `from_clause` in "gram.y".
public struct FromClause: Clause {
  public let tableReferences: FromList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.from), tableReferences)
  }

  public init(_ tableReferences: FromList) {
    self.tableReferences = tableReferences
  }
}
