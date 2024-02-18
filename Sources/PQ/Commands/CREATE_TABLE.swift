/* *************************************************************************************************
 CREATE_TABLE.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Storage parameter for tables.
public enum StorageParameter: SQLTokenSequence {
  case fillfactor(UInt8)
  case toastTupleTarget(Int)
  case parallelWorkers(Int)
  case autovacuumEnabled(Bool)

  // TODO: Add more parameters

  case other(key: String, value: SQLToken?)

  public var tokens: [SQLToken] {
    switch self {
    case .fillfactor(let value):
      return [.identifier("fillfactor"), SQLToken.Operator.equalTo, .numeric(value)]
    case .toastTupleTarget(let int):
      return [.identifier("toast_tuple_target"), SQLToken.Operator.equalTo, .numeric(int)]
    case .parallelWorkers(let int):
      return [.identifier("parallel_workers"), SQLToken.Operator.equalTo, .numeric(int)]
    case .autovacuumEnabled(let bool):
      return [.identifier("parallel_workers"), SQLToken.Operator.equalTo, bool ? .true : .false]
    case .other(let key, let value):
      if let value {
        return [.identifier(key), SQLToken.Operator.equalTo, value]
      }
      return [.identifier(key)]
    }
  }
}

/// Index parameters used in `CREATE(ALTER) TABLE`'s `UNIQUE`, `PRIMARY KEY`, and `EXCLUDE`.
public struct TableIndexParameters: SQLTokenSequence {
  /// `INCLUDE` clause.
  public var columns: [ColumnReference]?

  /// `WITH` clause.
  public var storageParameters: [StorageParameter]?

  /// `USING INDEX TABLESPACE` clause.
  public var tableSpaceName: String?

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    if let columns, !columns.isEmpty {
      tokens.append(contentsOf: [.include, .leftParenthesis, .joiner])
      tokens.append(contentsOf: columns.joined(separator: [.joiner, .comma]))
      tokens.append(contentsOf: [.joiner, .rightParenthesis])
    }
    if let storageParameters, !storageParameters.isEmpty {
      tokens.append(contentsOf: [.with, .leftParenthesis, .joiner])
      tokens.append(contentsOf: storageParameters.joined(separator: [.joiner, .comma]))
      tokens.append(contentsOf: [.joiner, .rightParenthesis])
    }
    if let tableSpaceName {
      tokens.append(contentsOf: [.using, .index, .tablespace, .identifier(tableSpaceName)])
    }
    return tokens
  }

  public init(columns: [ColumnReference]? = nil, storageParameters: [StorageParameter]? = nil, tableSpaceName: String? = nil) {
    self.columns = columns
    self.storageParameters = storageParameters
    self.tableSpaceName = tableSpaceName
  }
}

/// Match type used in `REFERENCES` of column constraint, or in `FOREIGN KEY` of table constraint.
public enum MatchType: String {
  case full
  case partial
  case simple

  fileprivate var token: SQLToken {
    switch self {
    case .full:
      return .full
    case .partial:
      return .partial
    case .simple:
      return .simple
    }
  }
}

/// An action performed on delete/update.
public enum ReferentialAction: SQLTokenSequence {
  case noAction
  case restrict
  case cascade
  case setNull(columns: [ColumnReference]?)
  case setDefault(columns: [ColumnReference]?)

  public var tokens: [SQLToken] {
    switch self {
    case .noAction:
      return [.no, .action]
    case .restrict:
      return [.restrict]
    case .cascade:
      return [.cascade]
    case .setNull(let columns):
      var tokens: [SQLToken] = [.set, .null]
      if let columns, !columns.isEmpty {
        tokens.append(contentsOf: [.with, .leftParenthesis, .joiner])
        tokens.append(contentsOf: columns.joined(separator: [.joiner, .comma]))
        tokens.append(contentsOf: [.joiner, .rightParenthesis])
      }
      return tokens
    case .setDefault(let columns):
      var tokens: [SQLToken] = [.set, .default]
      if let columns, !columns.isEmpty {
        tokens.append(contentsOf: [.with, .leftParenthesis, .joiner])
        tokens.append(contentsOf: columns.joined(separator: [.joiner, .comma]))
        tokens.append(contentsOf: [.joiner, .rightParenthesis])
      }
      return tokens
    }
  }
}

/// The default time to check the constraint.
public enum DefaultConstraintCheckingTime: String {
  case immediate
  case deferred

  fileprivate var token: SQLToken {
    switch self {
    case .immediate:
      return .immediate
    case .deferred:
      return .deferred
    }
  }
}

/// Representation of column constraint.
public struct ColumnConstraint: SQLTokenSequence {
  public enum Pattern: SQLTokenSequence {
    public enum GeneratedIdentityValueOption {
      case always
      case byDefault
    }

    case notNull
    case null
    case check(any SQLTokenSequence, noInherit: Bool = false)
    case `default`(any SQLTokenSequence)
    case generatedAndStores(generator: any SQLTokenSequence)
    case generatedAsIdentity(valueOption: GeneratedIdentityValueOption, sequenceOptions: [SequenceNumberGeneratorOption]? = nil)
    case unique(nullsNotDistinct: Bool? = nil, indexParameters: TableIndexParameters? = nil)
    case primaryKey(indexParameters: TableIndexParameters? = nil)
    case references(TableName, column: ColumnReference? = nil, matchType: MatchType? = nil, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil)

    public var tokens: [SQLToken] {
      switch self {
      case .notNull:
        return [.not, .null]
      case .null:
        return [.null]
      case .check(let expression, let noInherit):
        var tokens: [SQLToken] = [.check]
        tokens.append(contentsOf: expression.parenthesized)
        if noInherit {
          tokens.append(contentsOf: [.no, .inherit])
        }
        return tokens
      case .default(let expression):
        return [.default] + expression.tokens
      case .generatedAndStores(let generator):
        var tokens: [SQLToken] = [.generated, .always, .as]
        tokens.append(contentsOf: generator.parenthesized)
        tokens.append(.stored)
        return tokens
      case .generatedAsIdentity(let valueOption, let sequenceOptions):
        var tokens: [SQLToken] = [.generated]
        switch valueOption {
        case .always:
          tokens.append(.always)
        case .byDefault:
          tokens.append(contentsOf: [.by, .default])
        }
        tokens.append(contentsOf: [.as, .identity])
        if let sequenceOptions, !sequenceOptions.isEmpty {
          tokens.append(.leftParenthesis)
          tokens.append(contentsOf: sequenceOptions.joined())
          tokens.append(.rightParenthesis)
        }
        return tokens
      case .unique(let nullsNotDistinct, let indexParameters):
        var tokens: [SQLToken] = [.unique]
        nullsNotDistinct.map {
          if $0 {
            tokens.append(contentsOf: [.nulls, .not, .distinct])
          } else {
            tokens.append(contentsOf: [.nulls, .distinct])
          }
        }
        indexParameters.map { tokens.append(contentsOf: $0) }
        return tokens
      case .primaryKey(let indexParameters):
        var tokens: [SQLToken] = [.primary, .key]
        indexParameters.map { tokens.append(contentsOf: $0) }
        return tokens
      case .references(let tableName, let column, let matchType, let onDelete, let onUpdate):
        var tokens: [SQLToken] = [.references]
        tokens.append(contentsOf: tableName)
        column.map { tokens.append(contentsOf: $0.parenthesized) }
        matchType.map { tokens.append(contentsOf: [.match, $0.token]) }
        onDelete.map { tokens.append(contentsOf: [.on, .delete] + $0.tokens) }
        onUpdate.map { tokens.append(contentsOf: [.on, .update] + $0.tokens) }
        return tokens
      }
    }
  }

  public var name: String?

  public var pattern: Pattern

  public var deferrable: Bool?

  public var defaultConstraintCheckingTime: DefaultConstraintCheckingTime?

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    name.map { tokens.append(contentsOf: [.constraint, .identifier($0)]) }
    tokens.append(contentsOf: pattern)
    deferrable.map { $0 ? tokens.append(.deferrable) : tokens.append(contentsOf: [.not, .deferrable]) }
    defaultConstraintCheckingTime.map { tokens.append(contentsOf: [.initially, $0.token]) }
    return tokens
  }

  public init(
    name: String? = nil,
    pattern: Pattern,
    deferrable: Bool? = nil,
    defaultConstraintCheckingTime: DefaultConstraintCheckingTime? = nil
  ) {
    self.name = name
    self.pattern = pattern
    self.deferrable = deferrable
    self.defaultConstraintCheckingTime = defaultConstraintCheckingTime
  }
}
