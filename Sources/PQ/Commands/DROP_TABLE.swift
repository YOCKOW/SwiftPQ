/* *************************************************************************************************
 DROP_TABLE.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A representation of "DROP TABLE".
public struct DropTable: SQLTokenSequence {
  /// An option that indicates whether or not objects that depend on the table should be also removed.
  public enum Option {
    case cascade
    case restrict

    public var token: SQLToken {
      switch self {
      case .cascade: return .cascade
      case .restrict: return .restrict
      }
    }
  }

  public var tables: [TableName]

  public var ifExists: Bool

  public var option: Option?

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [.drop, .table]
    if ifExists {
      tokens.append(contentsOf: [.if, .exists])
    }
    tokens.append(contentsOf: tables.joinedByCommas())
    option.map { tokens.append($0.token) }
    return tokens
  }

  public init(_ tables: [TableName], ifExists: Bool = false, option: Option? = nil) {
    self.tables = tables
    self.ifExists = ifExists
    self.option = option
  }

  public init(_ name: TableName, ifExists: Bool = false, option: Option? = nil) {
    self.init([name], ifExists: ifExists, option: option)
  }
}
