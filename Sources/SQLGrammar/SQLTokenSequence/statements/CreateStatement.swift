/* *************************************************************************************************
 CreateStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type of `CREATE ... TABLE ...` that is described as `CreateStmt` in "gram.y".
public protocol CreateStatement: Statement {}

/// Ordinary `CREATE TABLE` statement.
public struct CreateTableStatement: CreateStatement {
  public let temporariness: TemporarinessOption?

  public let ifNotExists: Bool

  public let name: TableName

  public let definitions: TableElementList?

  public let inherits: InheritClause?

  public let partitionSpecification: PartitionSpecification?

  public let accessMethod: TableAccessMethodClause?

  public let storageParameters: WithStorageParametersClause?

  public let onCommit: OnCommitOption?

  public let tableSpace: TableSpaceSpecifier?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      SingleToken(.create),
      temporariness,
      SingleToken(.table),
      ifNotExists ? IfNotExists.ifNotExists : nil,
      name,
      LeftParenthesis.leftParenthesis,
      definitions,
      RightParenthesis.rightParenthesis,
      inherits,
      partitionSpecification,
      accessMethod,
      storageParameters,
      onCommit,
      tableSpace
    )
  }

  public init(
    temporariness: TemporarinessOption? = nil,
    ifNotExists: Bool = false,
    name: TableName,
    definitions: TableElementList?,
    inherits: InheritClause? = nil,
    partitionSpecification: PartitionSpecification? = nil,
    accessMethod: TableAccessMethodClause? = nil,
    storageParameters: WithStorageParametersClause? = nil,
    onCommit: OnCommitOption? = nil,
    tableSpace: TableSpaceSpecifier? = nil
  ) {
    self.temporariness = temporariness
    self.ifNotExists = ifNotExists
    self.name = name
    self.definitions = definitions
    self.inherits = inherits
    self.partitionSpecification = partitionSpecification
    self.accessMethod = accessMethod
    self.storageParameters = storageParameters
    self.onCommit = onCommit
    self.tableSpace = tableSpace
  }
}
