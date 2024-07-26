/* *************************************************************************************************
 NullTreatment.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A keywords to determine how to treat `NULL`.
/// It is described as `opt_unique_null_treatment` in "gram.y".
public enum NullTreatment: TokenSequenceGenerator {
  case distinct
  case notDistinct

  public class Tokens: Segment, TokenSequence {
    public let tokens: Array<Token>
    private init(_ tokens: Array<Token>) { self.tokens = tokens }
    public static let nullsDistinct: Tokens = .init([.nulls, .distinct])
    public static let nullsNotDistinct: Tokens = .init([.nulls, .not, .distinct])
  }

  public var tokens: Tokens {
    switch self {
    case .distinct:
      return .nullsDistinct
    case .notDistinct:
      return .nullsNotDistinct
    }
  }
}
