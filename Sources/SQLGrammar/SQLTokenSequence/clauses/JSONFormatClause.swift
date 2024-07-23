/* *************************************************************************************************
 JSONFormatClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that represents JSON encoding, described as `json_encoding_clause_opt` in "gram.y".
public struct JSONEncodingClause: Clause {
  public let name: ColumnIdentifier

  public var tokens: Array<SQLToken> {
    return [.encoding, name.token]
  }

  public init(name: ColumnIdentifier) {
    self.name = name
  }

  public static let utf8: JSONEncodingClause = .init(name: "UTF8")
}

/// A clause that represents JSON format, described as `json_format_clause_opt` in "gram.y".
public struct JSONFormatClause: Clause {
  public let encoding: JSONEncodingClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      SingleToken(.format),
      SingleToken(.json),
      encoding
    )
  }

  public init(encoding: JSONEncodingClause? = nil) {
    self.encoding = encoding
  }
}
