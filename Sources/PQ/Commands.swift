/* *************************************************************************************************
 Commands.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// MARK: - CREATE TABLE

extension Query {
  /// Create a query of "CREATE TABLE".
  ///
  /// - parameters:
  ///   * name: The name of the table.
  ///   * kind: Specify whether the created table is temporary, unlogged, or default.
  ///           A usual table will be created when `nil` is passed.
  ///   * columns: Column definitions.
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
    kind: TableKind? = nil,
    columns: [ColumnDefinition],
    ifNotExists: Bool = false,
    inherits parents: [TableName]? = nil,
    partitionBy partitioningStorategy: PartitioningStorategy? = nil,
    using tableAccessMethod: String? = nil,
    with storageParameters: [StorageParameter]? = nil,
    onCommit: TransactionEndStrategy? = nil,
    tableSpace: String? = nil
  ) -> Query {
    return .query(
      from: CreateTable(
        kind: kind,
        ifNotExists: ifNotExists,
        name: name,
        columns: columns,
        parents: parents,
        partitioningStorategy: partitioningStorategy,
        tableAccessMethod: tableAccessMethod,
        storageParameters: storageParameters,
        transactionEndStrategy: onCommit,
        tableSpaceName: tableSpace
      )
    )
  }

  /// The same method with `createTable` specifying `.temporary` for `kind`.
  @inlinable
  public static func createTemporaryTable(
    _ name: TableName,
    columns: [ColumnDefinition],
    ifNotExists: Bool = false,
    inherits parents: [TableName]? = nil,
    partitionBy partitioningStorategy: PartitioningStorategy? = nil,
    using tableAccessMethod: String? = nil,
    with storageParameters: [StorageParameter]? = nil,
    onCommit: TransactionEndStrategy? = nil,
    tableSpace: String? = nil
  ) -> Query {
    return createTable(
      name,
      kind: .temporary,
      columns: columns,
      ifNotExists: ifNotExists,
      inherits: parents,
      partitionBy: partitioningStorategy,
      using: tableAccessMethod,
      with: storageParameters,
      onCommit: onCommit,
      tableSpace: tableSpace
    )
  }

  /// The same method with `createTable` specifying `.unlogged` for `kind`.
  @inlinable
  public static func createUnloggedTable(
    _ name: TableName,
    columns: [ColumnDefinition],
    ifNotExists: Bool = false,
    inherits parents: [TableName]? = nil,
    partitionBy partitioningStorategy: PartitioningStorategy? = nil,
    using tableAccessMethod: String? = nil,
    with storageParameters: [StorageParameter]? = nil,
    onCommit: TransactionEndStrategy? = nil,
    tableSpace: String? = nil
  ) -> Query {
    return createTable(
      name,
      kind: .unlogged,
      columns: columns,
      ifNotExists: ifNotExists,
      inherits: parents,
      partitionBy: partitioningStorategy,
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
  ///   * kind: Specify whether the created table is temporary, unlogged, or default.
  ///           A usual table will be created when `nil` is passed.
  ///   * columns: Column definitions.
  ///   * ifNotExists: If true, An error is not thrown even if a table with the same name already exists.
  ///   * partitionBy: A strategy of partitioning the table.
  ///   * using: The table access method to use to store the contents for the new table.
  ///   * with: Storage parameters for a table.
  ///   * onCommit: The behavior of temporary tables at the end of a transaction block.
  ///   * tableSpace: The name of the tablespace.
  @inlinable
  public static func createTypedTable(
    _ name: TableName,
    of type: TypeName,
    kind: TableKind? = nil,
    columns: [TypedTableColumnDefinition]? = nil,
    ifNotExists: Bool = false,
    partitionBy partitioningStorategy: PartitioningStorategy? = nil,
    using tableAccessMethod: String? = nil,
    with storageParameters: [StorageParameter]? = nil,
    onCommit: TransactionEndStrategy? = nil,
    tableSpace: String? = nil
  ) -> Query {
    return .query(
      from: CreateTypedTable(
        kind: kind,
        ifNotExists: ifNotExists,
        name: name,
        typeName: type,
        columns: columns,
        partitioningStorategy: partitioningStorategy,
        tableAccessMethod: tableAccessMethod,
        storageParameters: storageParameters,
        transactionEndStrategy: onCommit,
        tableSpaceName: tableSpace
      )
    )
  }

  /// Create a query of "CREATE TABLE `table_name` PARTITION OF `parent_table`".
  ///
  /// - parameters:
  ///   * name: The name of the table.
  ///   * of type: The composite type that the table is tied to.
  ///   * kind: Specify whether the created table is temporary, unlogged, or default.
  ///           A usual table will be created when `nil` is passed.
  ///   * columns: Column definitions.
  ///   * ifNotExists: If true, An error is not thrown even if a table with the same name already exists.
  ///   * partitionBy: A strategy of partitioning the table.
  ///   * using: The table access method to use to store the contents for the new table.
  ///   * with: Storage parameters for a table.
  ///   * onCommit: The behavior of temporary tables at the end of a transaction block.
  ///   * tableSpace: The name of the tablespace.
  @inlinable
  public static func createPartitionTable(
    of parent: TableName,
    name: TableName,
    kind: TableKind? = nil,
    columns: [PartitionTableColumnDefinition]? = nil,
    ifNotExists: Bool = false,
    partitionType: CreatePartitionTable.PartitionType,
    partitionBy partitioningStorategy: PartitioningStorategy? = nil,
    using tableAccessMethod: String? = nil,
    with storageParameters: [StorageParameter]? = nil,
    onCommit: TransactionEndStrategy? = nil,
    tableSpace: String? = nil
  ) -> Query {
    return .query(
      from: CreatePartitionTable(
        kind: kind,
        ifNotExists: ifNotExists,
        name: name,
        parent: parent,
        columns: columns,
        partitionType: partitionType,
        partitioningStorategy: partitioningStorategy,
        tableAccessMethod: tableAccessMethod,
        storageParameters: storageParameters,
        transactionEndStrategy: onCommit,
        tableSpaceName: tableSpace
      )
    )
  }
}


// MARK: - DROP TABLE

extension Query {
  /// Create a query of "DROP TABLE"
  ///
  /// - Parameters:
  ///   * tables: A list of the tables to be removed.
  ///   * ifExists: If `true`, error is not thrown even if a table with the specified name doesn't exist.
  ///   * option: Specify the option that indicates whether or not objects that depend on the table should be also removed.
  public static func dropTable(
    _ tables: [TableName],
    ifExists: Bool = false,
    option: DropTable.Option? = nil
  ) -> Query {
    return .query(from: DropTable(tables, ifExists: ifExists, option: option))
  }

  /// Create a query of "DROP TABLE"
  ///
  /// - Parameters:
  ///   * name: The name of the table to be removed.
  ///   * ifExists: If `true`, error is not thrown even if a table with the specified name doesn't exist.
  ///   * option: Specify the option that indicates whether or not objects that depend on the table should be also removed.
  @inlinable
  public static func dropTable(
    _ name: TableName,
    ifExists: Bool = false,
    option: DropTable.Option? = nil
  ) -> Query {
    return dropTable([name], ifExists: ifExists, option: option)
  }
}
