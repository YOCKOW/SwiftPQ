/* *************************************************************************************************
 JSONPredicateType.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A JSON type that is described as `json_predicate_type_constraint` in "gram.y".
public enum JSONPredicateType: TokenSequence {
  case json
  case jsonValue
  case jsonArray
  case jsonObject
  case jsonScalar

  public final class Tokens: TokenSequence {
    public let tokens: Array<Token>
    private init(_ tokens: Array<Token>) { self.tokens = tokens }

    public static let json: Tokens = .init([.json])
    public static let jsonValue: Tokens = .init([.json, .value])
    public static let jsonArray: Tokens = .init([.json, .array])
    public static let jsonObject: Tokens = .init([.json, .object])
    public static let jsonScalar: Tokens = .init([.json, .scalar])
  }

  public var tokens: Tokens {
    switch self {
    case .json:
      return .json
    case .jsonValue:
      return .jsonValue
    case .jsonArray:
      return .jsonArray
    case .jsonObject:
      return .jsonObject
    case .jsonScalar:
      return .jsonScalar
    }
  }
}
