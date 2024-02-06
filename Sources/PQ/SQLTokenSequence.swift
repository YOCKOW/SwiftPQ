/* *************************************************************************************************
 SQLTokenSequence.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that holds a sequence of `SQLToken`.
public protocol SQLTokenSequence: Sequence where Iterator == Array<SQLToken>.Iterator, Element == SQLToken {
  var tokens: [SQLToken] { get }
}

extension SQLTokenSequence {
  public func makeIterator() -> Iterator {
    return tokens.makeIterator()
  }

  public var underestimatedCount: Int {
    return tokens.underestimatedCount
  }

  public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
    return try tokens.withContiguousStorageIfAvailable(body)
  }
}

internal extension Sequence where Element == SQLToken {
  var _description: String {
    var description = ""
    var previousToken: SQLToken? = nil
    for token in self {
      defer { previousToken = token }

      if token is SQLToken.Joiner {
        continue
      } else if previousToken is SQLToken.Joiner || previousToken == nil {
        description += token.description
      } else {
        description += " \(token.description)"
      }
    }
    return description
  }
}

extension SQLTokenSequence {
  public var description: String {
    return _description
  }
}

/// A type that represents a name of table.
public struct TableName: SQLTokenSequence {
  /// A name of schema.
  public var schema: String?

  /// A name of the table.
  public var name: String

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    if let schema {
      tokens.append(contentsOf: [.identifier(schema), .joiner, .dot, .joiner])
    }
    tokens.append(.identifier(name))
    return tokens
  }

  public init(schema: String? = nil, name: String) {
    self.schema = schema
    self.name = name
  }
}


/// A type that represents a column reference.
public struct ColumnReference: SQLTokenSequence {
  public var tableName: TableName?

  public var columnName: String

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    if let tableName {
      tokens.append(contentsOf: tableName.tokens)
      tokens.append(contentsOf: [.joiner, .dot, .joiner])
    }
    tokens.append(.identifier(columnName))
    return tokens
  }

  public init(tableName: TableName? = nil, columnName: String) {
    self.tableName = tableName
    self.columnName = columnName
  }
}
