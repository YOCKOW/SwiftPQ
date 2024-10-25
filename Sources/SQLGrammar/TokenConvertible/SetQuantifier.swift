/* *************************************************************************************************
 SetQuantifier.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A token that is described as `set_quantifier` in "gram.y".
public enum SetQuantifier: LosslessTokenConvertible, Sendable {
  case all
  case distinct

  @inlinable
  public var token: Token {
    switch self {
    case .all:
      return .all
    case .distinct:
      return .distinct
    }
  }

  @inlinable
  public init?(_ token: Token) {
    switch token {
    case .all:
      self = .all
    case .distinct:
      self = .distinct
    default:
      return nil
    }
  }
}
