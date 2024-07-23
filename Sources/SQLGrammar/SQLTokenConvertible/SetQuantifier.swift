/* *************************************************************************************************
 SetQuantifier.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A token that is described as `set_quantifier` in "gram.y".
public enum SetQuantifier: LosslessTokenConvertible {
  case all
  case distinct

  @inlinable
  public var token: SQLToken {
    switch self {
    case .all:
      return .all
    case .distinct:
      return .distinct
    }
  }

  @inlinable
  public init?(_ token: SQLToken) {
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
