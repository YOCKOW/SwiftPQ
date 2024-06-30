/* *************************************************************************************************
 ColumnConstraint.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element of column constraint that is described as `ColConstraintElem` in "gram.y".
public struct ColumnConstraintElement: SQLTokenSequence {
  public enum ConstraintType: SQLTokenSequence {
    case notNull
    
    case null

    case unique(
      NullTreatment?,
      WithDefinitionClause?,
      ConstraintTableSpaceClause?
    )

    case primaryKey(WithDefinitionClause?, ConstraintTableSpaceClause?)

    case check(any GeneralExpression, noInherit: Bool)

    case `default`(any RestrictedExpression)

    case generatedAsIdentity(GeneratedWhenClause, OptionalSequenceOptionList)

    case generatedAsStoredValue(GeneratedWhenClause, any GeneralExpression)

    case references(
      TableName,
      OptionalColumnList,
      MatchType?,
      ReferentialActionSet?
    )

    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .notNull:
        return JoinedSQLTokenSequence(NotNull.notNull)
      case .null:
        return JoinedSQLTokenSequence(SingleToken(.null))
      case .unique(let nullTreatment, let withDefinitionClause, let tableSpaceClause):
        return .compacting(
          SingleToken(.unique),
          nullTreatment,
          withDefinitionClause,
          tableSpaceClause
        )
      case .primaryKey(let withDefinitionClause, let tableSpaceClause):
        return .compacting(
          SingleToken(.primary), SingleToken(.key),
          withDefinitionClause,
          tableSpaceClause
        )
      case .check(let expr, let noInherit):
        return .compacting(
          SingleToken(.check),
          expr._asAny.parenthesized,
          noInherit ? NoInherit.noInherit : nil
        )
      case .default(let expr):
        return JoinedSQLTokenSequence([SingleToken(.default), expr])
      case .generatedAsIdentity(let when, let seqOptions):
        return JoinedSQLTokenSequence(
          SingleToken(.generated),
          when,
          SingleToken(.as),
          SingleToken(.identity),
          seqOptions
        )
      case .generatedAsStoredValue(let when, let generator):
        return JoinedSQLTokenSequence(
          SingleToken(.generated),
          when,
          SingleToken(.as),
          generator._asAny.parenthesized,
          SingleToken(.stored)
        )
      case .references(let refTable, let refColumns, let matchType, let actions):
        return .compacting(
          SingleToken(.references),
          refTable,
          refColumns,
          matchType,
          actions
        )
      }
    }
  }

  public let constraint: ConstraintType

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    return constraint.tokens
  }

  private init(constraint: ConstraintType) {
    self.constraint = constraint
  }

  /// Returns a `NOT NULL` constraint.
  public static let notNull: ColumnConstraintElement = .init(constraint: .notNull)

  /// Returns a `NULL` constraint.
  public static let null: ColumnConstraintElement = .init(constraint: .null)

  /// Creates a `UNIQUE ...` constraint.
  public static func unique(
    nulls: NullTreatment? = nil,
    with withDefinition: WithDefinitionClause? = nil,
    tableSpace: ConstraintTableSpaceClause? = nil
  ) -> ColumnConstraintElement {
    return .init(constraint: .unique(nulls, withDefinition, tableSpace))
  }

  /// Returns a `UNIQUE` constraint.
  public static let unique: ColumnConstraintElement = .unique()


  /// Creates a `PRIMARY KEY ...` constraint.
  public static func primaryKey(
    with withDefinition: WithDefinitionClause? = nil,
    tableSpace: ConstraintTableSpaceClause? = nil
  ) -> ColumnConstraintElement {
    return .init(constraint: .primaryKey(withDefinition, tableSpace))
  }

  /// Returns a `PRIMARY KEY` constraint.
  public static let primaryKey: ColumnConstraintElement = .primaryKey()

  /// Creates a `CHECK ...` constraint.
  public static func check<E>(
    _ expression: E,
    noInherit: Bool = false
  ) -> ColumnConstraintElement where E: GeneralExpression  {
    return .init(constraint: .check(expression, noInherit: noInherit))
  }

  /// Creates a `DEFAULT ...` constraint.
  public static func `default`<E>(
    _ expression: E
  ) -> ColumnConstraintElement where E: RestrictedExpression  {
    return .init(constraint: .default(expression))
  }

  /// Creates a `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY [ ( sequenceOptions ) ]` constraint.
  public static func generatedAsIdentity(
    _ when: GeneratedWhenClause,
    sequenceOptions: OptionalSequenceOptionList = nil
  ) -> ColumnConstraintElement {
    return .init(constraint: .generatedAsIdentity(when, sequenceOptions))
  }

  /// Creates a `GENERATED ALWAYS AS ( expression ) STORED` constraint.
  public static func generatedStoredValue<E>(
    from expression: E
  ) -> ColumnConstraintElement where E: GeneralExpression {
    return .init(constraint: .generatedAsStoredValue(.always, expression))
  }

  /// Creates a `REFERENCES ...` constraint.
  public static func references(
    referenceTable: TableName,
    referenceColumns: OptionalColumnList = nil,
    match matchType: MatchType? = nil,
    actions: ReferentialActionSet? = nil
  ) -> ColumnConstraintElement {
    return .init(
      constraint: .references(
        referenceTable,
        referenceColumns,
        matchType,
        actions
      )
    )
  }
}

/// Representation of `ConstraintAttr` in "gram.y".
public enum ColumnConstraintAttribute: SQLTokenSequence {
  case deferrable
  case notDeferrable
  case initiallyDeferred
  case initiallyImmediate

  public struct Tokens: SQLTokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }

    public static let deferrable: Tokens = .init([.deferrable])
    public static let notDeferrable: Tokens = .init([.not, .deferrable])
    public static let initiallyDeferred: Tokens = .init([.initially, .deferred])
    public static let initiallyImmediate: Tokens = .init([.initially, .immediate])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .deferrable:
      return .deferrable
    case .notDeferrable:
      return .notDeferrable
    case .initiallyDeferred:
      return .initiallyDeferred
    case .initiallyImmediate:
      return .initiallyImmediate
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}
