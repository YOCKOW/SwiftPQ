/* *************************************************************************************************
 NonReservedWord.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A representation of `NonReservedWord` in "gram.y".
public struct NonReservedWord: LosslessTokenConvertible, ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public let token: SQLToken

  public init?(_ token: SQLToken) {
    switch token {
    case is SQLToken.Identifier:
      self.token = token
    case let keyword as SQLToken.Keyword where (
      keyword.isUnreserved ||
      keyword.isAvailableForColumnName ||
      keyword.isAvailableForTypeOrFunctionName
    ):
      self.token = token
    default:
      return nil
    }
  }

  public init(_ description: String) {
    if let keyword = SQLToken.keyword(from: description), let word = Self(keyword) {
      self = word
      return
    }
    self.token = .identifier(description)
  }


  public init(stringLiteral value: String) {
    self.init(value)
  }

  /// "MODULUS"
  public static let modulus: NonReservedWord = "MODULUS"

  /// "REMAINDER"
  public static let remainder: NonReservedWord = "REMAINDER"
}
