/* *************************************************************************************************
 TableSpaceSpecifier.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Specifier of table space that is described as `OptTableSpace` in "gram.y".
public struct TableSpaceSpecifier: SQLTokenSequence {
  public let tableSpaceName: TableSpaceName

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.tablespace), tableSpaceName)
  }

  public init(_ tableSpaceName: TableSpaceName) {
    self.tableSpaceName = tableSpaceName
  }
}
