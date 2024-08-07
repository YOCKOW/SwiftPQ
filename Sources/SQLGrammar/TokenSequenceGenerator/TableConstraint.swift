/* *************************************************************************************************
 TableConstraint.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */


/// An element of constraint attribute that is described as `ConstraintAttributeElem` in "gram.y".
public enum TableConstraintAttributeElement: TokenSequence {
  case notDeferrable
  case deferrable
  case initiallyImmediate
  case initiallyDeferred
  case notValid
  case noInherit

  public struct Tokens: TokenSequence {
    public let tokens: Array<Token>
    private init(_ tokens: Array<Token>) { self.tokens = tokens }

    public static let notDeferrable: Tokens = .init([.not, .deferrable])
    public static let deferrable: Tokens = .init([.deferrable])
    public static let initiallyImmediate: Tokens = .init([.initially, .immediate])
    public static let initiallyDeferred: Tokens = .init([.initially, .deferred])
    public static let notValid: Tokens = .init([.not, .valid])
    public static let noInherit: Tokens = .init([.no, .inherit])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .notDeferrable:
      return .notDeferrable
    case .deferrable:
      return .deferrable
    case .initiallyImmediate:
      return .initiallyImmediate
    case .initiallyDeferred:
      return .initiallyDeferred
    case .notValid:
      return .notValid
    case .noInherit:
      return .noInherit
    }
  }
}

/// A list of `TableConstraintAttributeElement` that is described as
/// `ConstraintAttributeSpec` in "gram.y".
public struct TableConstraintAttributeSpecification: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = TableConstraintAttributeElement

  public var elements: Array<TableConstraintAttributeElement>

  public var tokens: JoinedTokenSequence {
    return elements.joined()
  }

  @inlinable
  public mutating func append(_ newElement: TableConstraintAttributeElement) {
    elements.append(newElement)
  }

  @inlinable
  public mutating func append<S>(
    contentsOf newElements: S
  ) where S: Sequence, S.Element == TableConstraintAttributeElement {
    elements.append(contentsOf: newElements)
  }

  public init() {
    self.elements = []
  }

  public init(_ elements: Array<TableConstraintAttributeElement>) {
    self.elements = elements
  }

  @inlinable
  public init(arrayLiteral elements: TableConstraintAttributeElement...) {
    self.init(elements)
  }
}

/// `opt_c_include` in "gram.y".
public struct ConstraintIncludeClause: Clause {
  public let columns: ColumnList

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(SingleToken.include, columns.parenthesized)
  }

  public init(columns: ColumnList) {
    self.columns = columns
  }
}

private extension Optional where Wrapped == TableConstraintAttributeSpecification {
  init(_ optionalElements: Optional<TableConstraintAttributeElement>...) {
    let elements = optionalElements.compactMap({ $0 })
    if elements.isEmpty {
      self = .none
    } else {
      self = .some(TableConstraintAttributeSpecification(elements))
    }
  }
}

/// Representation of `ExistingIndex` in "gram.y".
public struct ExistingIndex: TokenSequenceGenerator {
  public let name: Name

  private static let _usingIndexTokens = UnknownSQLTokenSequence<Array<Token>>([.using, .index])
  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(ExistingIndex._usingIndexTokens, name)
  }

  public init(_ name: Name) {
    self.name = name
  }
}

/// An element used in an `EXCLUDE` constraint. This is described as `ExclusionConstraintElem` in
/// "gram.y".
public struct ExclusionConstraintElement: TokenSequenceGenerator {
  public enum Operator: TokenSequenceGenerator {
    case bare(LabeledOperator)
    case constructor(OperatorConstructor)

    @inlinable
    public var tokens: JoinedTokenSequence {
      switch self {
      case .bare(let labeledOperator):
        return labeledOperator.tokens
      case .constructor(let operatorConstructor):
        return operatorConstructor.tokens
      }
    }
  }

  public let element: IndexElement

  public let `operator`: Operator

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(element, SingleToken.with, `operator`)
  }

  private init(element: IndexElement, operator: Operator) {
    self.element = element
    self.operator = `operator`
  }

  public init(_ element: IndexElement, with operator: LabeledOperator) {
    self.init(element: element, operator: .bare(`operator`))
  }

  public init(_ element: IndexElement, with operator: OperatorConstructor) {
    self.init(element: element, operator: .constructor(`operator`))
  }
}

/// A list of `ExclusionConstraintElement`. This is described as `ExclusionConstraintList` in
/// "gram.y".
public struct ExclusionConstraintList: TokenSequenceGenerator,
                                       InitializableWithNonEmptyList,
                                       ExpressibleByArrayLiteral {
  public typealias NonEmptyListElement = ExclusionConstraintElement
  public typealias ArrayLiteralElement = ExclusionConstraintElement

  public var elements: NonEmptyList<ExclusionConstraintElement>

  public var tokens: JoinedTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<ExclusionConstraintElement>) {
    self.elements = elements
  }
}

/// An element of table constraint that is described as `ConstraintElem` in "gram.y".
public struct TableConstraintElement: TokenSequenceGenerator {
  public enum ConstraintType: TokenSequenceGenerator {
    case check(any GeneralExpression)

    case unique(
      NullTreatment?,
      ColumnList,
      ConstraintIncludeClause?,
      WithDefinitionClause?,
      ConstraintTableSpaceClause?
    )

    case uniqueUsingIndex(ExistingIndex)

    case primaryKey(
      ColumnList,
      ConstraintIncludeClause?,
      WithDefinitionClause?,
      ConstraintTableSpaceClause?
    )

    case primaryKeyUsingIndex(ExistingIndex)

    case exclude(
      AccessMethodClause?,
      ExclusionConstraintList,
      ConstraintIncludeClause?,
      WithDefinitionClause?,
      ConstraintTableSpaceClause?,
      WhereParenthesizedExpressionClause?
    )

    case foreignKey(
      ColumnList,
      TableName,
      OptionalColumnList,
      MatchType?,
      ReferentialActionSet?
    )

    public var tokens: JoinedTokenSequence {
      switch self {
      case .check(let expr):
        return JoinedTokenSequence(SingleToken.check, expr._asAny.parenthesized)
      case .unique(
        let nullTreatment,
        let columnList,
        let includeClause,
        let withDefinitionClause,
        let tableSpaceCaluse
      ):
        return .compacting(
          SingleToken.unique,
          nullTreatment,
          columnList.parenthesized,
          includeClause,
          withDefinitionClause,
          tableSpaceCaluse
        )
      case .uniqueUsingIndex(let index):
        return JoinedTokenSequence(SingleToken.unique, index)
      case .primaryKey(
        let columnList,
        let includeClause,
        let withDefinitionClause,
        let tableSpaceClause
      ):
        return .compacting(
          SingleToken.primary, SingleToken.key,
          columnList.parenthesized,
          includeClause,
          withDefinitionClause,
          tableSpaceClause
        )
      case .primaryKeyUsingIndex(let index):
        return JoinedTokenSequence(SingleToken.primary, SingleToken.key, index)
      case .exclude(
        let accessMethodClause,
        let constraintList,
        let includeClause,
        let withDefinitionClause,
        let tableSpaceClause,
        let whereClause
      ):
        return .compacting(
          SingleToken.exclude,
          accessMethodClause,
          constraintList.parenthesized,
          includeClause,
          withDefinitionClause,
          tableSpaceClause,
          whereClause
        )
      case .foreignKey(
        let columns,
        let refTable,
        let refColumns,
        let matchType,
        let actions
      ):
        return .compacting(
          SingleToken.foreign, SingleToken.key,
          columns.parenthesized,
          SingleToken.references,
          refTable,
          refColumns,
          matchType,
          actions
        )
      }
    }
  }

  public let constraint: ConstraintType

  public let attributes: TableConstraintAttributeSpecification?

  public var tokens: JoinedTokenSequence {
    return .compacting(constraint, attributes)
  }

  private init(constraint: ConstraintType, attributes: TableConstraintAttributeSpecification?) {
    self.constraint = constraint
    self.attributes = attributes
  }

  /// Creates a `CHECK` constraint.
  public static func check<Expr>(
    _ expression: Expr,
    noInherit: Bool = false,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement where Expr: GeneralExpression {
    return TableConstraintElement(
      constraint: .check(expression),
      attributes: .init(
        noInherit ? .noInherit : nil,
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }

  /// Creates a `UNIQUE` constraint.
  public static func unique(
    nulls: NullTreatment? = nil,
    columns: ColumnList,
    include: ConstraintIncludeClause? = nil,
    with withDefinition: WithDefinitionClause? = nil,
    tableSpace: ConstraintTableSpaceClause? = nil,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement {
    return TableConstraintElement(
      constraint: .unique(
        nulls,
        columns,
        include,
        withDefinition,
        tableSpace
      ),
      attributes: .init(
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }

  public static func uniqueUsingIndex(
    _ existingIndex: ExistingIndex,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement {
    return TableConstraintElement(
      constraint: .uniqueUsingIndex(existingIndex),
      attributes: .init(
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }

  /// Creates a `PRIMARY KEY` constraint.
  public static func primaryKey(
    columns: ColumnList,
    include: ConstraintIncludeClause? = nil,
    with withDefinition: WithDefinitionClause? = nil,
    tableSpace: ConstraintTableSpaceClause? = nil,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement {
    return TableConstraintElement(
      constraint: .primaryKey(columns, include, withDefinition, tableSpace),
      attributes: .init(
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }

  public static func primaryKeyUsingIndex(
    _ existingIndex: ExistingIndex,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement {
    return TableConstraintElement(
      constraint: .primaryKeyUsingIndex(existingIndex),
      attributes: .init(
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }

  /// Creates an `EXCLUDE` constraint.
  public static func exclude(
    using accessMethod: AccessMethodClause? = nil,
    elements: ExclusionConstraintList,
    include: ConstraintIncludeClause? = nil,
    with withDefinition: WithDefinitionClause? = nil,
    tableSpace: ConstraintTableSpaceClause? = nil,
    where predicateClause: WhereParenthesizedExpressionClause? = nil,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement {
    return TableConstraintElement(
      constraint: .exclude(
        accessMethod,
        elements,
        include,
        withDefinition,
        tableSpace,
        predicateClause
      ),
      attributes: .init(
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }

  /// Creates a `FOREIGN KEY` constraint.
  public static func foreignKey(
    columns: ColumnList,
    referenceTable: TableName,
    referenceColumns: OptionalColumnList = nil,
    match matchType: MatchType? = nil,
    actions: ReferentialActionSet? = nil,
    deferrable: DeferrableConstraintOption? = nil,
    checkConstraint: ConstraintCheckingTimeOption? = nil
  ) -> TableConstraintElement {
    return TableConstraintElement(
      constraint: .foreignKey(
        columns,
        referenceTable,
        referenceColumns,
        matchType,
        actions
      ),
      attributes: .init(
        deferrable?.tableConstraintAttributeElement,
        checkConstraint?.tableConstraintAttributeElement
      )
    )
  }
}

/// Representation of `TableConstraint` in "gram.y".
public struct TableConstraint: TokenSequenceGenerator {
  public let name: Name?
  
  public let constraint: TableConstraintElement

  public var tokens: JoinedTokenSequence {
    return .compacting(
      name.map({ JoinedTokenSequence(SingleToken.constraint, $0) }),
      constraint
    )
  }

  public init(name: Name? = nil, constraint: TableConstraintElement) {
    self.name = name
    self.constraint = constraint
  }
}
