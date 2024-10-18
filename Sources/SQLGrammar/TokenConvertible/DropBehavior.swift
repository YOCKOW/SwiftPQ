/* *************************************************************************************************
 DropBehavior.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that specifies drop behavior.
public enum DropBehavior: LosslessTokenConvertible, Sendable {
  case cascade
  case restrict

  public var token: Token {
    switch self {
    case .cascade:
      return .cascade
    case .restrict:
      return .restrict
    }
  }

  public init?(_ token: Token) {
    guard case let keyword as Token.Keyword = token else { return nil }
    switch keyword {
    case .cascade:
      self = .cascade
    case .restrict:
      self = .restrict
    default:
      return nil
    }
  }
}
