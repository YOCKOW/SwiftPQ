/* *************************************************************************************************
 ColumnIdentifier.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a column identifier which is described as `ColId` in "gram.y".
///
/// - Note: `ColId` is not always used as a name of column in "gram.y".
public struct ColumnIdentifier: LosslessTokenConvertible {
  public let token: SQLToken

  public init?(_ token: SQLToken) {
    switch token {
    case is SQLToken.Identifier:
      self.token = token
    case let keyword as SQLToken.Keyword where (keyword.isUnreserved || keyword.isAvailableForColumnName):
      self.token = keyword
    default:
      return nil
    }
  }
}

extension ColumnIdentifier: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.init(.identifier(value))!
  }
}
