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

/// A type that represents nulls order.
public enum NullOrdering: Segment {
  /// NULLS FIRST
  case first

  /// NULLS LAST
  case last

  private static let _nullsFirst: Array<SQLToken> = [.nulls, .first]
  private static let _nullsLast: Array<SQLToken> = [.nulls, .last]

  public var tokens: Array<SQLToken> {
    switch self {
    case .first:
      return Self._nullsFirst
    case .last:
      return Self._nullsLast
    }
  }
}
