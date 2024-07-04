/* *************************************************************************************************
 JSONPredicateType.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A JSON type that is described as `json_predicate_type_constraint` in "gram.y".
public enum JSONPredicateType: SQLTokenSequence {
  case json
  case jsonValue
  case jsonArray
  case jsonObject
  case jsonScalar

  public final class Tokens: SQLTokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }

    fileprivate static let json: Tokens = .init([.json])
    fileprivate static let jsonValue: Tokens = .init([.json, .value])
    fileprivate static let jsonArray: Tokens = .init([.json, .array])
    fileprivate static let jsonObject: Tokens = .init([.json, .object])
    fileprivate static let jsonScalar: Tokens = .init([.json, .scalar])
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

  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}
