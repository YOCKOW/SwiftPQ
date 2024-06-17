/* *************************************************************************************************
 NullTreatment.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A keywords to determine how to treat `NULL`.
/// It is described as `opt_unique_null_treatment` in "gram.y".
public enum NullTreatment: SQLTokenSequence {
  case distinct
  case notDistinct

  public class Tokens: Segment {
    public let tokens: Array<SQLToken>
    init(_ tokens: Array<SQLToken>) { self.tokens = tokens }
  }
  private final class _NullsDistinct: Tokens {
    private init() { super.init([.nulls, .distinct]) }
    static let nullsDistinct: _NullsDistinct = .init()
  }
  private final class _NullsNotDistinct: Tokens {
    private init() { super.init([.nulls, .not, .distinct]) }
    static let nullsNotDistinct: _NullsNotDistinct = .init()
  }

  public var tokens: Tokens {
    switch self {
    case .distinct:
      return _NullsDistinct.nullsDistinct
    case .notDistinct:
      return _NullsNotDistinct.nullsNotDistinct
    }
  }

  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}
