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

public struct SingleToken: SQLTokenSequence {
  public var token: SQLToken

  public var tokens: [SQLToken] {
    return [token]
  }

  public var isPositionalParameter: Bool {
    return token is SQLToken.PositionalParameter
  }

  public var isIdentifier: Bool {
    return token is SQLToken.Identifier || token is SQLToken.DelimitedIdentifier
  }

  public static func positionalParameter(_ position: UInt) throws -> SingleToken {
    return .init(token: try .positionalParameter(position))
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

public struct Subscript: SQLTokenSequence {
  public enum Parameter {
    case index(Int)
    case slice(lower: Int?, upper: Int?)

    public var tokens: [SQLToken] {
      switch self {
      case .index(let index):
        return [.leftSquareBracket, .joiner, .numeric(index), .joiner, .rightSquareBracket]
      case .slice(lower: let lower, upper: let upper):
        var tokens: [SQLToken] = [.leftSquareBracket, .joiner]
        if let lower {
          tokens.append(contentsOf: [.numeric(lower), .joiner])
        }
        tokens.append(contentsOf: [.colon])
        if let upper {
          tokens.append(contentsOf: [.joiner, .numeric(upper)])
        }
        tokens.append(contentsOf: [.joiner, .rightSquareBracket])
        return tokens
      }
    }
  }

  /// Preceding expression from that a value is extracted.
  public var expression: any SQLTokenSequence

  public var parameter: Parameter

  public var tokens: [SQLToken] {
    let omitParentheses: Bool = switch expression {
    case let singleToken as SingleToken where singleToken.isPositionalParameter: true
    case is ColumnReference: true
    case is Subscript: true
    default: false
    }

    var tokens: [SQLToken] = omitParentheses ? [] : [.leftParenthesis, .joiner]
    tokens.append(contentsOf: expression.tokens)
    if !omitParentheses {
      tokens.append(contentsOf: [.joiner, .rightParenthesis])
    }
    tokens.append(.joiner)
    tokens.append(contentsOf: parameter.tokens)
    return tokens
  }

  public init(expression: any SQLTokenSequence, parameter: Parameter) {
    self.expression = expression
    self.parameter = parameter
  }
}
