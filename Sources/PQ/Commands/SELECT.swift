/* *************************************************************************************************
 SELECT.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SQLGrammar

extension Query {
  /// Create a simple `SELECT` query.
  @inlinable
  public static func select(
    _ expressions: (any GeneralExpression)...
  ) -> Query {
    let targets: TargetList? = NonEmptyList<TargetElement>(items: expressions.map(\.asTarget)).map {
      TargetList($0)
    }

    let statement = SimpleSelectQuery(targets: targets)

    return .query(from: statement)
  }
}
