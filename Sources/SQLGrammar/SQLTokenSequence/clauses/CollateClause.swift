/* *************************************************************************************************
 CollateClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that overrides the collation of an expression,
/// described as `opt_collate_clause` in "gram.y".
public struct CollateClause: Clause {
  public let name: CollationName

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.collate), name)
  }

  public init(name: CollationName) {
    self.name = name
  }
}
