/* *************************************************************************************************
 ColumnLabel.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a column label which is described as `ColLabel` in "gram.y".
public struct ColumnLabel: LosslessTokenConvertible {
  public let token: Token

  public init?(_ token: Token) {
    switch token {
    case is Token.Identifier:
      self.token = token
    case let keyword as Token.Keyword where (
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

  public init(_ description: String) {
    if let keyword = Token.keyword(from: description),
       let id = Self(keyword) {
      self = id
      return
    }
    self.token = .identifier(description)
  }
}

extension ColumnLabel: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.init(.identifier(value))!
  }
}
