/* *************************************************************************************************
 DROP_TABLE.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SQLGrammar

extension Query {
  /// Create a query of "DROP TABLE"
  ///
  /// - Parameters:
  ///   * tables: A list of the tables to be removed.
  ///   * ifExists: If `true`, error is not thrown even if a table with the specified name doesn't exist.
  ///   * behavior: Specify the option that indicates whether or not objects that depend on the table should be also removed.
  @inlinable
  public static func dropTable(
    _ tables: NonEmptyList<TableName>,
    ifExists: Bool = false,
    behavior: DropBehavior? = nil
  ) -> Query {
    return .query(from: DropTableStatement(names: tables, ifExists: ifExists, behavior: behavior)!)
  }

  /// Create a query of "DROP TABLE"
  ///
  /// - Parameters:
  ///   * name: The name of the table to be removed.
  ///   * ifExists: If `true`, error is not thrown even if a table with the specified name doesn't exist.
  ///   * behavior: Specify the option that indicates whether or not objects that depend on the table should be also removed.
  @inlinable
  public static func dropTable(
    _ name: TableName,
    ifExists: Bool = false,
    behavior: DropBehavior? = nil
  ) -> Query {
    return .query(from: DropTableStatement(ifExists: ifExists, name: name, behavior: behavior))
  }
}
