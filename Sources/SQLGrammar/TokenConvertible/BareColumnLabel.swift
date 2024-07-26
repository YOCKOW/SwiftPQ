/* *************************************************************************************************
 BareColumnLabel.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a bare column label which is described as `BareColLabel` in "gram.y".
public struct BareColumnLabel: LosslessTokenConvertible {
  public let token: Token

  public init?(_ token: Token) {
    switch token {
    case is Token.Identifier:
      self.token = token
    case let keyword as Token.Keyword where keyword.isBareLabel:
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

extension BareColumnLabel: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self.init(.identifier(value))!
  }
}
