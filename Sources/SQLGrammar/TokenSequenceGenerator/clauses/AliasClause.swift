/* *************************************************************************************************
 AliasClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause described as `alias_clause` in "gram.y".
public struct AliasClause: Clause {
  /// A boolean value that indicates whether or not `AS` token is omitted.
  public var omitAsToken: Bool = false

  /// Alias name.
  public let alias: ColumnIdentifier

  /// Represents `name_list`
  public let columnAliases: NameList?

  public var tokens: JoinedSQLTokenSequence {
    var sequences: [any TokenSequenceGenerator] = omitAsToken ? [] : [SingleToken.as]
    sequences.append(alias.asSequence)
    if let columnAliases {
      sequences.append(columnAliases.parenthesized)
    }
    return JoinedSQLTokenSequence(sequences)
  }

  public init(alias: ColumnIdentifier, columnAliases: NameList? = nil) {
    self.alias = alias
    self.columnAliases = columnAliases
  }
}
