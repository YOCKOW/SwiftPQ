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

/// Representation of `CONSTRAINT name ColConstraintElem` or `ColConstraintElem` in "gram.y".
public struct NamedColumnConstraint: SQLTokenSequence {
  public var name: Name?

  public var element: ColumnConstraintElement

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(name.map({ JoinedSQLTokenSequence(SingleToken(.constraint), $0) }), element)
  }

  public init(name: Name? = nil, element: ColumnConstraintElement) {
    self.name = name
    self.element = element
  }
}

/// Representation of `ColConstraint` in "gram.y".
///
/// This type includes `ConstraintAttr` and `COLLATE any_name`, and thus it is different from
/// `TableConstraint` syntactically.
/// So the name of this type is `ColumnQualifier` instead of `ColumnConstraint`.
public struct ColumnQualifier: SQLTokenSequence {
  public enum QualifierType: SQLTokenSequence {
    case constraint(NamedColumnConstraint)
    case attribute(ColumnConstraintAttribute)
    case collation(Collation)

    public struct Iterator: IteratorProtocol {
      public typealias Element = SQLToken
      private let _iterator: AnySQLTokenSequenceIterator
      fileprivate init<S>(_ sequence: S) where S: SQLTokenSequence {
        self._iterator = sequence._asAny.makeIterator()
      }
      public func next() -> SQLToken? {
        return _iterator.next()
      }
    }

    public typealias Tokens = Self

    public func makeIterator() -> Iterator {
      switch self {
      case .constraint(let constraint):
         return Iterator(constraint)
      case .attribute(let attr):
        return Iterator(attr)
      case .collation(let collation):
        return Iterator(collation)
      }
    }
  }

  public let qualifier: QualifierType

  @inlinable
  public var tokens: QualifierType.Tokens {
    return qualifier.tokens
  }

  @inlinable
  public func makeIterator() -> QualifierType.Tokens.Iterator {
    return tokens.makeIterator()
  }

  private init(qualifier: QualifierType) {
    self.qualifier = qualifier
  }

  /// Creates a constraint qualifier.
  public static func constraint(_ constraint: NamedColumnConstraint) -> ColumnQualifier {
    return .init(qualifier: .constraint(constraint))
  }

  /// Creates a constraint qualifier.
  @inlinable
  public static func constraint(name: Name? = nil, element: ColumnConstraintElement) -> ColumnQualifier {
    return .constraint(NamedColumnConstraint(name: name, element: element))
  }

  /// Creates a constraint qualifier.
  @inlinable
  public static func constraint(_ constraint: ColumnConstraintElement) -> ColumnQualifier {
    return .constraint(name: nil, element: constraint)
  }

  /// Creates an attribute qualifier.
  public static func attribute(_ attribute: ColumnConstraintAttribute)-> ColumnQualifier {
    return .init(qualifier: .attribute(attribute))
  }

  /// Creates a collation qualifier.
  public static func collation(_ collation: Collation) -> ColumnQualifier {
    return .init(qualifier: .collation(collation))
  }

  /// Creates a collation qualifier.
  public static func collation(_ collationName: CollationName) -> ColumnQualifier {
    return .init(qualifier: .collation(Collation(name: collationName)))
  }
}

private protocol _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { get }
}
extension Collation: _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { .collation(self) }
}
extension CollationName: _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { .collation(self) }
}
extension ColumnConstraintElement: _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { .constraint(self) }
}
extension NamedColumnConstraint: _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { .constraint(self) }
}
extension DeferrableConstraintOption: _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { .attribute(self.columnConstraintAttribute) }
}
extension ConstraintCheckingTimeOption: _ColumnQualifierConvertible {
  var _columnQualifier: ColumnQualifier { .attribute(self.columnConstraintAttribute) }
}

/// A list of column qualifiers. This is described as `ColQualList` in "gram.y".
public struct ColumnQualifierList: SQLTokenSequence {
  /// Column constraint described as `column_constraint` in
  /// [Official Documentation](https://www.postgresql.org/docs/current/sql-createtable.html).
  public struct Constraint {
    public var constraint: NamedColumnConstraint

    @inlinable
    public var name: Name? {
      get {
        return constraint.name
      }
      set {
        constraint.name = newValue
      }
    }

    @inlinable
    public var element: ColumnConstraintElement {
      get {
        return constraint.element
      }
      set {
        constraint.element = newValue
      }
    }

    public var deferrable: DeferrableConstraintOption?

    public var constraintCheckingTime: ConstraintCheckingTimeOption?

    public init(
      constraint: NamedColumnConstraint,
      deferrable: DeferrableConstraintOption? = nil,
      checkConstraint timing: ConstraintCheckingTimeOption? = nil
    ) {
      self.constraint = constraint
      self.deferrable = deferrable
      self.constraintCheckingTime = timing
    }

    public init(
      constraint: ColumnConstraintElement,
      deferrable: DeferrableConstraintOption? = nil,
      checkConstraint timing: ConstraintCheckingTimeOption? = nil
    ) {
      self.init(
        constraint: NamedColumnConstraint(element: constraint),
        deferrable: deferrable,
        checkConstraint: timing
      )
    }
  }

  public var collation: Collation?

  public var constraints: [Constraint]?

  /// A list of qualifiers.
  ///
  /// Order of qualifiers may matter. That's why this is a computed property.
  public var qualifiers: [ColumnQualifier] {
    var result: [ColumnQualifier] = []

    collation.map({ result.append($0._columnQualifier) })
    
    if let constraints = self.constraints {
      for constraintItem in constraints {
        result.append(constraintItem.constraint._columnQualifier)
        constraintItem.deferrable.map({ result.append($0._columnQualifier) })
        constraintItem.constraintCheckingTime.map({ result.append($0._columnQualifier) })
      }
    }

    return result
  }

  public var tokens: JoinedSQLTokenSequence {
    return qualifiers.joined()
  }

  /// Creates a list of column qualifiers with given properties.
  public init(collation: Collation? = nil, constraints: [Constraint]? = nil) {
    self.collation = collation
    self.constraints = constraints
  }

  /// Creates a list of column qualifiers with given properties.
  public init(collation: CollationName, constraints: [Constraint]? = nil) {
    self.collation = Collation(name: collation)
    self.constraints = constraints
  }
}
