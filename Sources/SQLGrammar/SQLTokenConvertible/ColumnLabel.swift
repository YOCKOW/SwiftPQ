/* *************************************************************************************************
 ColumnLabel.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a column label which is described as `ColLabel` in "gram.y".
public struct ColumnLabel: LosslessTokenConvertible {
  public let token: SQLToken

  public init?(_ token: SQLToken) {
    switch token {
    case is SQLToken.Identifier:
      self.token = token
    case let keyword as SQLToken.Keyword where (
      keyword.isUnreserved ||
      keyword.isAvailableForColumnName ||
      keyword.isAvailableForTypeOrFunctionName ||
      keyword.isReserved
    ):
      self.token = keyword
    default:
      return nil
    }
  }
}

