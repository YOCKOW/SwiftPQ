/* *************************************************************************************************
 MatchType.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A match type used when referencing tables or columns. This is described as `key_match` in
///  "gram.y".
public enum MatchType: SQLTokenSequence {
  case full
  case partial
  case simple

  public struct Tokens: SQLTokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }

    public static let full: Tokens = .init([.match, .full])
    public static let partial: Tokens = .init([.match, .partial])
    public static let simple: Tokens = .init([.match, .simple])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .full:
      return .full
    case .partial:
      return .partial
    case .simple:
      return .simple
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}
