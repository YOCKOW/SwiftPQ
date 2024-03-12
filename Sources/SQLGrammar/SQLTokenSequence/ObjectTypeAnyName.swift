/* *************************************************************************************************
 ObjectTypeAnyName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a name which is described as `object_type_any_name` in "gram.y".
public enum ObjectTypeAnyName: SQLTokenSequence {
  case table
  case sequence
  case view
  case materializedView
  case index
  case foreignTable
  case collation
  case conversion
  case statistics
  case textSearchParser
  case textSearchDictionary
  case textSearchTemplate
  case textSearchConfiguration

  public var tokens: Array<SQLToken> {
    switch self {
    case .table:
      return [.table]
    case .sequence:
      return [.sequence]
    case .view:
      return [.view]
    case .materializedView:
      return [.materialized, .view]
    case .index:
      return [.index]
    case .foreignTable:
      return [.foreign, .table]
    case .collation:
      return [.collation]
    case .conversion:
      return [.conversion]
    case .statistics:
      return [.statistics]
    case .textSearchParser:
      return [.text, .search, .parser]
    case .textSearchDictionary:
      return [.text, .search, .dictionary]
    case .textSearchTemplate:
      return [.text, .search, .template]
    case .textSearchConfiguration:
      return [.text, .search, .configuration]
    }
  }
}
