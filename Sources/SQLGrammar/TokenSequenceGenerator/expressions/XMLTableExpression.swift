/* *************************************************************************************************
 XMLTableExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An expression described as `xmltable` in "gram.y".
public struct XMLTableExpression: Expression {
  /// A clause represented by `COLUMNS xmltable_column_list`.
  public struct ColumnsClause: Clause {
    /// An option that is described as `xmltable_column_option_el` in "gram.y".
    public enum Option: TokenSequenceGenerator {
      // "gram.y" accepts `IDENT b_expr`, but the `IDENT` must be "PATH" according to the document.
      // https://www.postgresql.org/docs/current/functions-xml.html#FUNCTIONS-XML-PROCESSING-XMLTABLE

      case path(any RestrictedExpression)
      case `default`(any RestrictedExpression)
      case notNull
      case null

      private static let _pathToken = SingleToken(Token.identifier("PATH"))

      public var tokens: JoinedSQLTokenSequence {
        switch self {
        case .path(let columnExpr):
          return JoinedSQLTokenSequence([
            Option._pathToken,
            columnExpr,
          ] as [any TokenSequenceGenerator])
        case .default(let defaultExpr):
          return JoinedSQLTokenSequence([
            SingleToken(.default),
            defaultExpr,
          ] as [any TokenSequenceGenerator])
        case .notNull:
          return JoinedSQLTokenSequence([
            SingleToken(.not),
            SingleToken(.null),
          ] as [any TokenSequenceGenerator])
        case .null:
          return JoinedSQLTokenSequence([
            SingleToken(.null),
          ] as [any TokenSequenceGenerator])
        }
      }

      fileprivate var _sortOrder: Int {
        switch self {
        case .path:
          return 0
        case .default:
          return 1
        case .notNull:
          return 2
        case .null:
          return 3
        }
      }
    }

    /// A list of column options, that is described as `xmltable_column_option_list` in "gram.y".
    public struct OptionList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
      public let options: NonEmptyList<Option>

      public var tokens: JoinedSQLTokenSequence {
        // Sort options based on https://www.postgresql.org/docs/current/functions-xml.html#FUNCTIONS-XML-PROCESSING-XMLTABLE
        return JoinedSQLTokenSequence(options.sorted(by: { $0._sortOrder < $1._sortOrder }))
      }

      public init(_ options: NonEmptyList<Option>) {
        self.options = options
      }

      public init(arrayLiteral elements: Option...) {
        guard let nonEmptyOptions = NonEmptyList<Option>(items: elements) else {
          fatalError("\(Self.self): No options?!")
        }
        self.init(nonEmptyOptions)
      }
    }

    /// An element of column to be produced in the output table,
    /// that is described as `xmltable_column_el` in "gram.y".
    public struct ColumnElement: TokenSequenceGenerator {
      private enum _Element {
        case name(ColumnIdentifier, type: TypeName, options: OptionList?)
        case forOrdinality(name: ColumnIdentifier)
      }

      private let _element: _Element

      public var tokens: JoinedSQLTokenSequence {
        switch _element {
        case .name(let name, let type, let options):
          return .compacting(name.asSequence, type, options)
        case .forOrdinality(let name):
          return JoinedSQLTokenSequence(
            name.asSequence,
            SingleToken(.for),
            SingleToken(.ordinality)
          )
        }
      }

      public var name: ColumnIdentifier {
        switch _element {
        case .name(let name, _, _):
          return name
        case .forOrdinality(let name):
          return name
        }
      }

      public var type: TypeName? {
        guard case .name(_, let type, _) = _element else {
          return nil
        }
        return type
      }

      public var options: OptionList? {
        guard case .name(_, _, let options) = _element else {
          return nil
        }
        return options
      }

      private init(_ element: _Element) {
        self._element = element
      }

      public init(name: ColumnIdentifier, type: TypeName, options: OptionList? = nil) {
        self.init(.name(name, type: type, options: options))
      }

      public init(nameForOrdinality name: ColumnIdentifier) {
        self.init(.forOrdinality(name: name))
      }

      public static func forOrdinality(withName name: ColumnIdentifier) -> ColumnElement {
        return .init(nameForOrdinality: name)
      }
    }

    /// A list of columns, that is described as `xmltable_column_list` in "gram.y".
    public struct ColumnList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
      public let columns: NonEmptyList<ColumnElement>

      public var tokens: JoinedSQLTokenSequence {
        return columns.joinedByCommas()
      }

      public init(_ columns: NonEmptyList<ColumnElement>) {
        self.columns = columns
      }

      public init(arrayLiteral elements: ColumnElement...) {
        guard let nonEmptyColumns = NonEmptyList<ColumnElement>(items: elements) else {
          fatalError("\(Self.self): Empty columns?!")
        }
        self.init(nonEmptyColumns)
      }
    }

    public let columns: ColumnList

    public var tokens: JoinedSQLTokenSequence {
      return JoinedSQLTokenSequence(SingleToken(.columns), columns)
    }

    public init(_ columns: ColumnList) {
      self.columns = columns
    }
  }

  public let namespaces: XMLNamespaceList?

  public let row: any ProductionExpression

  public let passing: XMLPassingArgument

  public let columns: ColumnsClause

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmltable).followedBy(parenthesized: JoinedSQLTokenSequence.compacting([
      namespaces.map({
        JoinedSQLTokenSequence(
          SingleToken(.xmlnamespaces).followedBy(parenthesized: $0),
          commaSeparator
        )
      }),
      row,
      passing,
      columns,
    ] as [(any TokenSequenceGenerator)?]))
  }

  public init(
    namespaces: XMLNamespaceList? = nil,
    row: any ProductionExpression,
    passing: XMLPassingArgument,
    columns: ColumnsClause
  ) {
    self.namespaces = namespaces
    self.row = row
    self.passing = passing
    self.columns = columns
  }
}
