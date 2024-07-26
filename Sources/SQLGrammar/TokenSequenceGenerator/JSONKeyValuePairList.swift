/* *************************************************************************************************
 JSONKeyValuePairList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A list of JSON key-value pairs, described as `json_name_and_value_list` in "gram.y".
public struct JSONKeyValuePairList: TokenSequenceGenerator {
  public let pairs: NonEmptyList<JSONKeyValuePair>

  public var tokens: JoinedTokenSequence {
    return pairs.joinedByCommas()
  }

  public init(_ pairs: NonEmptyList<JSONKeyValuePair>) {
    self.pairs = pairs
  }
}

extension JSONKeyValuePairList: ExpressibleByDictionaryLiteral {
  public typealias Key = any GeneralExpression
  public typealias Value = JSONValueExpression

  public init(dictionaryLiteral elements: (any GeneralExpression, JSONValueExpression)...) {
    guard let keyValuePairs = NonEmptyList<JSONKeyValuePair>(items: elements.map {
      JSONKeyValuePair(key: $0.0, value: $0.1)
    }) else {
      fatalError("\(Self.self): Empty list not allowed.")
    }
    self.init(keyValuePairs)
  }
}
