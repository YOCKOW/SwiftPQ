/* *************************************************************************************************
 JSONKeyUniquenessOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to determine key uniquness in JSON object,
/// described as `json_key_uniqueness_constraint_opt` in "gram.y".
public enum JSONKeyUniquenessOption: TokenSequenceGenerator {
  case withUniqueKeys
  case withUnique
  case withoutUniqueKeys
  case withoutUnique

  private static let _withUniqueKeys: Array<SQLToken> = [.with, .unique, .keys]
  private static let _withUnique: Array<SQLToken> = [.with, .unique]
  private static let _withoutUniqueKeys: Array<SQLToken> = [.without, .unique, .keys]
  private static let _withoutUnique: Array<SQLToken> = [.without, .unique]

  public var tokens: Array<SQLToken> {
    switch self {
    case .withUniqueKeys:
      return JSONKeyUniquenessOption._withUniqueKeys
    case .withUnique:
      return JSONKeyUniquenessOption._withUnique
    case .withoutUniqueKeys:
      return JSONKeyUniquenessOption._withoutUniqueKeys
    case .withoutUnique:
      return JSONKeyUniquenessOption._withoutUnique
    }
  }
}
