/* *************************************************************************************************
 WindowExclusionClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause to specify which rows should be exluded.
/// The clause is described as `opt_window_exclusion_clause` in "gram.y".
public enum WindowExclusionClause: Clause {
  case excludeCurrentRow
  case excludeGroup
  case excludeTies
  case excludeNoOthers

  private static let _excludeCurrentRowTokens: Array<Token> = [.exclude, .current, .row]
  private static let _excludeGroupTokens: Array<Token> = [.exclude, .group]
  private static let _excludeTiesTokens: Array<Token> = [.exclude, .ties]
  private static let _excludeNoOthersTokens: Array<Token> = [.exclude, .no, .others]

  public var tokens: Array<Token> {
    switch self {
    case .excludeCurrentRow:
      return WindowExclusionClause._excludeCurrentRowTokens
    case .excludeGroup:
      return WindowExclusionClause._excludeGroupTokens
    case .excludeTies:
      return WindowExclusionClause._excludeTiesTokens
    case .excludeNoOthers:
      return WindowExclusionClause._excludeNoOthersTokens
    }
  }
}
