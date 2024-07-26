/* *************************************************************************************************
 ConstraintTableSpaceClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private let _usingIndexTableSpaceTokens = UnknownSQLTokenSequence<Array<SQLToken>>([
  .using,
  .index,
  .tablespace,
])

/// A clause described as `OptConsTableSpace` in "gram.y".
public struct ConstraintTableSpaceClause: Clause {
  public let tableSpaceName: TableSpaceName

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(_usingIndexTableSpaceTokens, tableSpaceName)
  }

  public init(_ tableSpaceName: TableSpaceName) {
    self.tableSpaceName = tableSpaceName
  }
}
