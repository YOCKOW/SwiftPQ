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
  public let columnAliases: [ColumnIdentifier]?

  public var tokens: JoinedSQLTokenSequence {
    var sequences: [any SQLTokenSequence] = omitAsToken ? [] : [SingleToken(.as)]
    sequences.append(alias.asSequence)
    if let columnAliases, !columnAliases.isEmpty {
      sequences.append(columnAliases.joinedByCommas().parenthesized)
    }
    return JoinedSQLTokenSequence(sequences)
  }

  public init(alias: ColumnIdentifier, columnAliases: [ColumnIdentifier]? = nil) {
    self.alias = alias
    self.columnAliases = columnAliases
  }
}
