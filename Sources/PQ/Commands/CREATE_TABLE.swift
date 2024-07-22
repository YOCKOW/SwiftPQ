/* *************************************************************************************************
 CREATE_TABLE.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SQLGrammar

extension Query {
  /// Create a query of "CREATE TABLE".
  ///
  /// - parameters:
  ///   * name: The name of the table.
  ///   * temporariness: Specify whether the created table is temporary, unlogged, or default.
  ///           A usual table will be created when `nil` is passed.
  ///   * definitions: Column definitions, table `LIKE` clauses, or table constraints.
  ///   * ifNotExists: If true, An error is not thrown even if a table with the same name already exists.
  ///   * inherits: A list of tables from which the new table automatically inherits all columns.
  ///   * partitionBy: A strategy of partitioning the table.
  ///   * using: The table access method to use to store the contents for the new table.
  ///   * with: Storage parameters for a table.
  ///   * onCommit: The behavior of temporary tables at the end of a transaction block.
  ///   * tableSpace: The name of the tablespace.
  @inlinable
  public static func createTable(
    _ name: TableName,
    temporariness: TemporarinessOption? = nil,
    definitions: TableElementList?,
    ifNotExists: Bool = false,
    inherits parents: QualifiedNameList<TableName>? = nil,
    partitionBy partitionSpecification: PartitionSpecification? = nil,
    using tableAccessMethod: Name? = nil,
    with storageParameters: StorageParameterList? = nil,
    onCommit: OnCommitOption? = nil,
    tableSpace: TableSpaceName? = nil
  ) -> Query {
    return .query(
      from: CreateTableStatement(
        temporariness: temporariness,
        ifNotExists: ifNotExists,
        name: name,
        definitions: definitions,
        inherits: parents.map({ InheritClause($0) }),
        partitionSpecification: partitionSpecification,
        accessMethod: tableAccessMethod.map({ TableAccessMethodClause(methodName: $0) }),
        storageParameters: storageParameters.map({ WithStorageParametersClause($0) }),
        onCommit: onCommit,
        tableSpace: tableSpace.map({ TableSpaceSpecifier($0) })
      )
    )
  }


  /// The same method with `createTable` specifying `.temporary` for `temporariness`.
  @inlinable
  public static func createTemporaryTable(
    _ name: TableName,
    definitions: TableElementList?,
    ifNotExists: Bool = false,
    inherits parents: QualifiedNameList<TableName>? = nil,
    partitionBy partitionSpecification: PartitionSpecification? = nil,
    using tableAccessMethod: Name? = nil,
    with storageParameters: StorageParameterList? = nil,
    onCommit: OnCommitOption? = nil,
    tableSpace: TableSpaceName? = nil
  ) -> Query {
    return .createTable(
      name,
      temporariness: .temporary,
      definitions: definitions,
      ifNotExists: ifNotExists,
      inherits: parents,
      partitionBy: partitionSpecification,
      using: tableAccessMethod,
      with: storageParameters,
      onCommit: onCommit,
      tableSpace: tableSpace
    )
  }


  /// The same method with `createTable` specifying `.unlogged` for `temporariness`.
  @inlinable
  public static func createUnloggedTable(
    _ name: TableName,
    definitions: TableElementList?,
    ifNotExists: Bool = false,
    inherits parents: QualifiedNameList<TableName>? = nil,
    partitionBy partitionSpecification: PartitionSpecification? = nil,
    using tableAccessMethod: Name? = nil,
    with storageParameters: StorageParameterList? = nil,
    onCommit: OnCommitOption? = nil,
    tableSpace: TableSpaceName? = nil
  ) -> Query {
    return .createTable(
      name,
      temporariness: .unlogged,
      definitions: definitions,
      ifNotExists: ifNotExists,
      inherits: parents,
      partitionBy: partitionSpecification,
      using: tableAccessMethod,
      with: storageParameters,
      onCommit: onCommit,
      tableSpace: tableSpace
    )
  }

  /// Create a query of "CREATE TABLE `table_name` OF `type_name`".
  ///
  /// - parameters:
  ///   * name: The name of the table.
  ///   * of type: The composite type that the table is tied to.
  ///   * temporariness: Specify whether the created table is temporary, unlogged, or default.
  ///                    A usual table will be created when `nil` is passed.
  ///   * definitions: Column definitions, or table constraints.
  ///   * ifNotExists: If true, An error is not thrown even if a table with the same name already exists.
  ///   * partitionBy: A strategy of partitioning the table.
  ///   * using: The table access method to use to store the contents for the new table.
  ///   * with: Storage parameters for a table.
  ///   * onCommit: The behavior of temporary tables at the end of a transaction block.
  ///   * tableSpace: The name of the tablespace.
  @inlinable
  public static func createTypedTable(
    _ name: TableName,
    of type: CompositeTypeName,
    temporariness: TemporarinessOption? = nil,
    definitions: OptionalTypedTableElementList = nil,
    ifNotExists: Bool = false,
    partitionBy partitionSpecification: PartitionSpecification? = nil,
    using tableAccessMethod: Name? = nil,
    with storageParameters: StorageParameterList? = nil,
    onCommit: OnCommitOption? = nil,
    tableSpace: TableSpaceName? = nil
  ) -> Query {
    return .query(
      from: CreateTypedTableStatement(
        temporariness: temporariness,
        ifNotExists: ifNotExists,
        name: name,
        of: type,
        definitions: definitions,
        partitionSpecification: partitionSpecification,
        accessMethod: tableAccessMethod.map({ TableAccessMethodClause(methodName: $0) }),
        storageParameters: storageParameters.map({ WithStorageParametersClause($0) }),
        onCommit: onCommit,
        tableSpace: tableSpace.map({ TableSpaceSpecifier($0) })
      )
    )
  }

  /// Create a query of "CREATE TABLE `table_name` PARTITION OF `parent_table`".
  ///
  /// - parameters:
  ///   * name: The name of the table.
  ///   * partitionOf parentTable: The name of the parent table.
  ///   * temporariness: Specify whether the created table is temporary, unlogged, or default.
  ///                    A usual table will be created when `nil` is passed.
  ///   * definitions: Column definitions, or table constraints.
  ///   * ifNotExists: If true, An error is not thrown even if a table with the same name already exists.
  ///   * partitionBoundSpecification: Bounds that correspondd to the partitioning method and
  ///                                  partition key of the parent table.
  ///   * partitionBy: A strategy of partitioning the table.
  ///   * using: The table access method to use to store the contents for the new table.
  ///   * with: Storage parameters for a table.
  ///   * onCommit: The behavior of temporary tables at the end of a transaction block.
  ///   * tableSpace: The name of the tablespace.
  ///   *
  @inlinable
  public static func createTable(
    _ name: TableName,
    partitionOf parentTable: TableName,
    temporariness: TemporarinessOption? = nil,
    definitions: OptionalTypedTableElementList = nil,
    ifNotExists: Bool = false,
    partitionBoundSpecification: PartitionBoundSpecification,
    partitionBy partitionSpecification: PartitionSpecification? = nil,
    using tableAccessMethod: Name? = nil,
    with storageParameters: StorageParameterList? = nil,
    onCommit: OnCommitOption? = nil,
    tableSpace: TableSpaceName? = nil
  ) -> Query {
    return .query(
      from: CreatePartitionTableStatement(
        temporariness: temporariness,
        ifNotExists: ifNotExists,
        name: name,
        partitionOf: parentTable,
        definitions: definitions,
        partitionBoundSpecification: partitionBoundSpecification,
        partitionSpecification: partitionSpecification,
        accessMethod: tableAccessMethod.map({ TableAccessMethodClause(methodName: $0) }),
        storageParameters: storageParameters.map({ WithStorageParametersClause($0) }),
        onCommit: onCommit,
        tableSpace: tableSpace.map({ TableSpaceSpecifier($0) })
      )
    )
  }
}
