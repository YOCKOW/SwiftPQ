/* *************************************************************************************************
 Index.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `index_elem_options` in "gram.y".
public struct IndexElementOptionSet: TokenSequenceGenerator {
  public struct OperatorClassOption: TokenSequenceGenerator {
    public let name: OperatorClass

    public let parameters: StorageParameterList?

    private var _parameters: _StorageParameters? {
      return parameters.map(_StorageParameters.init)
    }

    public var tokens: JoinedSQLTokenSequence {
      return .compacting(name, _parameters)
    }

    public init(name: OperatorClass, parameters: StorageParameterList? = nil) {
      self.name = name
      self.parameters = parameters
    }
  }

  public let collation: Collation?

  public let operatorClass: OperatorClassOption?

  public let sortOrder: SortDirection?

  public let nullsOrder: NullOrdering?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(collation, operatorClass, sortOrder?.asSequence, nullsOrder)
  }

  public init(
    collation: Collation? = nil,
    operatorClass: OperatorClassOption? = nil,
    sortOrder: SortDirection? = nil,
    nullsOrder: NullOrdering? = nil
  ) {
    self.collation = collation
    self.operatorClass = operatorClass
    self.sortOrder = sortOrder
    self.nullsOrder = nullsOrder
  }
}

/// Representation of `index_elem` in "gram.y".
public struct IndexElement: TokenSequenceGenerator {
  public enum Column {
    case name(ColumnIdentifier)
    case functionCall(any WindowlessFunctionExpression)
    case expression(any GeneralExpression)

    fileprivate var _tokens: AnyTokenSequenceGenerator {
      switch self {
      case .name(let id):
        return id.asSequence._asAny
      case .functionCall(let expr):
        return expr._asAny
      case .expression(let expr):
        return expr._asAny.parenthesized._asAny
      }
    }
  }

  public let column: Column

  public let options: IndexElementOptionSet?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(column._tokens, options)
  }
  
  private init(column: Column, options: IndexElementOptionSet?) {
    self.column = column
    self.options = options
  }


  public init(columnName: ColumnIdentifier, options: IndexElementOptionSet? = nil) {
    self.init(column: .name(columnName), options: options)
  }

  public init<E>(
    expression: E,
    options: IndexElementOptionSet? = nil
  ) where E: WindowlessFunctionExpression {
    self.init(column: .functionCall(expression), options: options)
  }

  public init<E>(
    expression: E,
    options: IndexElementOptionSet? = nil
  ) where E: GeneralExpression {
    self.init(column: .expression(expression), options: options)
  }
}


/// A list of `IndexElement`. This is described as `index_params` in "gram.y".
public struct IndexElementList: TokenSequenceGenerator,
                                InitializableWithNonEmptyList,
                                ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = IndexElement
  public typealias ArrayLiteralElement = IndexElement

  public var elements: NonEmptyList<IndexElement>

  public var tokens: JoinedSQLTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<IndexElement>) {
    self.elements = elements
  }
}
