/* *************************************************************************************************
 FrameClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A bound that specifies frame start or end. It is described as `frame_bound` in "gram.y".
public enum FrameBound: SQLTokenSequence {
  case unboundedPreceding
  case unboundedFollowing
  case currentRow
  case preceding(offset: any GeneralExpression)
  case following(offset: any GeneralExpression)

  private static let _unboundedPrecedingTokens: UnknownSQLTokenSequence<Array<SQLToken>> = .init([
    .unbounded, .preceding,
  ])
  private static let _unboundedFollowingTokens: UnknownSQLTokenSequence<Array<SQLToken>> = .init([
    .unbounded, .following,
  ])
  private static let _currentRowTokens: UnknownSQLTokenSequence<Array<SQLToken>> = .init([
    .current, .row,
  ])

  public var tokens: JoinedSQLTokenSequence {
    switch self {
    case .unboundedPreceding:
      return JoinedSQLTokenSequence(FrameBound._unboundedPrecedingTokens)
    case .unboundedFollowing:
      return JoinedSQLTokenSequence(FrameBound._unboundedFollowingTokens)
    case .currentRow:
      return JoinedSQLTokenSequence(FrameBound._currentRowTokens)
    case .preceding(let offset):
      return JoinedSQLTokenSequence([offset, SingleToken(.preceding)] as [any SQLTokenSequence])
    case .following(let offset):
      return JoinedSQLTokenSequence([offset, SingleToken(.following)] as [any SQLTokenSequence])
    }
  }
}

/// A range of frame, that is described as `frame_extent` in "gram.y".
public struct FrameExtent: SQLTokenSequence {
  public let start: FrameBound

  public let end: FrameBound?

  public var tokens: JoinedSQLTokenSequence {
    guard let end = self.end else {
      return JoinedSQLTokenSequence(start)
    }
    return JoinedSQLTokenSequence(SingleToken(.between), start, SingleToken(.and), end)
  }

  public init(start: FrameBound, end: FrameBound?) {
    self.start = start
    self.end = end
  }
}

/// A clause that is described as `opt_frame_clause` in "gram.y".
public struct FrameClause: Clause {
  public enum Mode: LosslessTokenConvertible {
    case range
    case rows
    case groups

    public var token: SQLToken {
      switch self {
      case .range:
        return .range
      case .rows:
        return .rows
      case .groups:
        return .groups
      }
    }

    public init?(_ token: SQLToken) {
      switch token {
      case .range:
        self = .range
      case .rows:
        self = .rows
      case .groups:
        self = .groups
      default:
        return nil
      }
    }
  }

  public let mode: Mode

  public let extent: FrameExtent

  public let exclusion: WindowExclusionClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(SingleToken(mode), extent, exclusion)
  }

  public init(mode: Mode, extent: FrameExtent, exclusion: WindowExclusionClause? = nil) {
    self.mode = mode
    self.extent = extent
    self.exclusion = exclusion
  }
}