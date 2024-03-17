/* *************************************************************************************************
 SortClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Sort direction.
public enum SortDirection: LosslessTokenConvertible {
  case ascending
  case descending
  public static let `default`: SortDirection = .ascending

  public var token: SQLToken {
    switch self {
    case .ascending:
      return .asc
    case .descending:
      return .desc
    }
  }

  public init?(_ token: SQLToken) {
    guard case let keyword as SQLToken.Keyword = token else { return nil }
    if keyword == .asc {
      self = .ascending
    } else if keyword == .desc {
      self = .descending
    } else {
      return nil
    }
  }
}
