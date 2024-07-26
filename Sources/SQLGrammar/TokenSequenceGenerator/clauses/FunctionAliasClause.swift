/* *************************************************************************************************
 FunctionAliasClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that is described as `func_alias_clause` in "gram.y".
public struct FunctionAliasClause: Clause {
  private enum _Alias {
    case simpleAlias(AliasClause)
    case aliasWithTableFunctionElementList(
      omitAsToken: Bool,
      alias: ColumnIdentifier?,
      list: TableFunctionElementList
    )
  }

  private var _alias: _Alias

  public var tokens: JoinedTokenSequence {
    switch _alias {
    case .simpleAlias(let aliasClause):
      return aliasClause.tokens
    case .aliasWithTableFunctionElementList(let omitAsToken, let alias, let list):
      var sequences: [any TokenSequenceGenerator] = omitAsToken ? [] : [SingleToken.as]
      if let alias {
        sequences.append(alias.asSequence)
      }
      sequences.append(list.parenthesized)
      return JoinedTokenSequence(sequences)
    }
  }

  /// A boolean value that indicates whether or not `AS` token is omitted.
  public var omitAsToken: Bool {
    get {
      switch _alias {
      case .simpleAlias(let aliasClause):
        return aliasClause.omitAsToken
      case .aliasWithTableFunctionElementList(let omitAsToken, _, _):
        return omitAsToken
      }
    }
    set {
      switch _alias {
      case .simpleAlias(var aliasClause):
        aliasClause.omitAsToken = newValue
        self._alias = .simpleAlias(aliasClause)
      case .aliasWithTableFunctionElementList(_, let alias, let list):
        self._alias = .aliasWithTableFunctionElementList(
          omitAsToken: newValue,
          alias: alias,
          list: list
        )
      }
    }
  }

  /// Alias name.
  public var alias: ColumnIdentifier? {
    switch _alias {
    case .simpleAlias(let aliasClause):
      return aliasClause.alias
    case .aliasWithTableFunctionElementList(_, let alias, _):
      return alias
    }
  }

  /// Column aliases.
  public var columnAliases: NameList? {
    guard case .simpleAlias(let clause) = _alias else {
      return nil
    }
    return clause.columnAliases
  }

  /// Column definitions.
  public var columnDefinitions: TableFunctionElementList? {
    guard case .aliasWithTableFunctionElementList(_, _, let list) = _alias else {
      return nil
    }
    return list
  }

  /// Creates a clause which is the same with `AliasClause`.
  public init(_ aliasClause: AliasClause) {
    self._alias = .simpleAlias(aliasClause)
  }

  /// Creates a clause which is the same with `AliasClause` from given parameters.
  public init(alias: ColumnIdentifier, columnAliases: NameList? = nil) {
    self.init(AliasClause(alias: alias, columnAliases: columnAliases))
  }

  public init(alias: ColumnIdentifier?, columnDefinitions: TableFunctionElementList) {
    self._alias = .aliasWithTableFunctionElementList(
      omitAsToken: false,
      alias: alias,
      list: columnDefinitions
    )
  }
}
