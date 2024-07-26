/* *************************************************************************************************
 TableFunction.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element that is described as `TableFuncElement` in "gram.y".
public struct TableFunctionElement: TokenSequenceGenerator {
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
public struct TableFunctionElementList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
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


/// A list of column definitions, that is described as `opt_col_def_list` in "gram.y".
public struct ColumnDefinitionList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public let list: TableFunctionElementList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken.as, list.parenthesized)
  }

  public init(_ list: TableFunctionElementList) {
    self.list = list
  }

  public init(arrayLiteral elements: TableFunctionElement...) {
    guard let nonEmptyElements = NonEmptyList<TableFunctionElement>(items: elements) else {
      fatalError("No elements?!")
    }
    self.init(TableFunctionElementList(nonEmptyElements))
  }
}

/// A clause that is described as `opt_ordinality` in "gram.y".
private final class WithOrdinalityClause: Clause {
  let tokens: Array<Token> = [.with, .ordinality]
  private init() {}
  static let withOrdinality: WithOrdinalityClause = .init()
}

/// A part of table function that is described as `func_table` in "gram.y"
public struct TableFunction: TokenSequenceGenerator {
  /// A syntax described as `ROWS FROM '(' rowsfrom_list ')'` in "gram.y"
  public struct RowsFromSyntax: TokenSequenceGenerator {
    /// An item described as `rowsfrom_item` in "gram.y".
    public struct Item: TokenSequenceGenerator {
      public let functionCall: any WindowlessFunctionExpression

      public let columnDefinitions: ColumnDefinitionList?

      public var tokens: JoinedSQLTokenSequence {
        return .compacting([functionCall, columnDefinitions] as [(any TokenSequenceGenerator)?])
      }

      public init(
        functionCall: any WindowlessFunctionExpression,
        columnDefinitions: ColumnDefinitionList? = nil
      ) {
        self.functionCall = functionCall
        self.columnDefinitions = columnDefinitions
      }
    }

    /// A list of `rowsfrom_item`s that is described as `rowsfrom_list` in "gram.y".
    public struct List: TokenSequenceGenerator, ExpressibleByArrayLiteral {
      public let items: NonEmptyList<RowsFromSyntax.Item>

      public var tokens: JoinedSQLTokenSequence {
        return items.joinedByCommas()
      }

      public init(_ items: NonEmptyList<RowsFromSyntax.Item>) {
        self.items = items
      }

      public init(arrayLiteral elements: RowsFromSyntax.Item...) {
        guard let items = NonEmptyList(items: elements) else {
          fatalError("\(Self.self): No items?!")
        }
        self.init(items)
      }
    }

    public let list: List

    private final class _RowsFromTokens: TokenSequenceGenerator {
      let tokens: Array<Token> = [.rows, .from]
      private init() {}
      static let rowsFromTokens: _RowsFromTokens = .init()
    }

    public var tokens: JoinedSQLTokenSequence {
      return _RowsFromTokens.rowsFromTokens.followedBy(parenthesized: list)
    }

    public init(_ list: List) {
      self.list = list
    }
  }

  private enum _Kind {
    case functionCall(any WindowlessFunctionExpression)
    case rowsFromSyntax(RowsFromSyntax)
  }

  private let _kind: _Kind

  public let withOrdinality: Bool

  public var tokens: JoinedSQLTokenSequence {
    var sequences: [any TokenSequenceGenerator] = []

    switch _kind {
    case .functionCall(let expr):
      sequences.append(expr)
    case .rowsFromSyntax(let rowsFromSyntax):
      sequences.append(rowsFromSyntax)
    }

    if withOrdinality {
      sequences.append(WithOrdinalityClause.withOrdinality)
    }

    return JoinedSQLTokenSequence(sequences)
  }

  public init(functionCall: any WindowlessFunctionExpression, withOrdinality: Bool = false) {
    self._kind = .functionCall(functionCall)
    self.withOrdinality = withOrdinality
  }

  public init(rowsFrom: RowsFromSyntax, withOrdinality: Bool = false) {
    self._kind = .rowsFromSyntax(rowsFrom)
    self.withOrdinality = withOrdinality
  }
}

