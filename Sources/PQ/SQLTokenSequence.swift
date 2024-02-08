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

  public var isInteger: Bool {
    return (token as? SQLToken.NumericConstant)?.isInteger == true
  }

  public var isFloat: Bool {
    return (token as? SQLToken.NumericConstant)?.isFloat == true
  }

  public var isNegativeNumeric: Bool {
    return (token as? SQLToken.NumericConstant)?.isNegative == true
  }

  public static func positionalParameter(_ position: UInt) throws -> SingleToken {
    return .init(token: try .positionalParameter(position))
  }

  public static func integer<T>(_ integer: T) -> SingleToken where T: FixedWidthInteger {
    return .init(token: .numeric(integer))
  }

  public static func float<T>(_ float: T) -> SingleToken where T: BinaryFloatingPoint & CustomStringConvertible {
    return .init(token: .numeric(float))
  }
}

public struct ParenthesizedExpression: SQLTokenSequence {
  public var expression: any SQLTokenSequence

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [.leftParenthesis, .joiner]
    tokens.append(contentsOf: expression.tokens)
    tokens.append(contentsOf: [.joiner, .rightParenthesis])
    return tokens
  }

  public init(expression: any SQLTokenSequence) {
    self.expression = expression
  }
}

extension SQLTokenSequence {
  public var parenthesized: ParenthesizedExpression {
    return ParenthesizedExpression(expression: self)
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

    var tokens: [SQLToken] = omitParentheses ? expression.tokens : expression.parenthesized.tokens
    tokens.append(.joiner)
    tokens.append(contentsOf: parameter.tokens)
    return tokens
  }

  public init(expression: any SQLTokenSequence, parameter: Parameter) {
    self.expression = expression
    self.parameter = parameter
  }
}

public struct FieldSelection: SQLTokenSequence {
  public enum Field {
    case name(String)
    case all
  }

  /// Preceding expression from that a field is selected.
  public var expression: any SQLTokenSequence

  public var field: Field

  public var tokens: [SQLToken] {
    let omitParentheses: Bool = switch expression {
    case let singleToken as SingleToken where singleToken.isPositionalParameter: true
    case let tableName as TableName where tableName.schema == nil: true
    default: false
    }

    var tokens = omitParentheses ? expression.tokens : expression.parenthesized.tokens
    tokens.append(contentsOf: [.joiner, .dot, .joiner])
    switch field {
    case .name(let string):
      tokens.append(.identifier(string))
    case .all:
      tokens.append(.asterisk)
    }
    return tokens
  }

  public init(expression: any SQLTokenSequence, field: Field) {
    self.expression = expression
    self.field = field
  }
}

public enum Operator: SQLTokenSequence {
  case single(SQLToken.Operator)
  case qualified(schema: String, operator: SQLToken.Operator)
  case and
  case or
  case not

  public var tokens: [SQLToken] {
    switch self {
    case .single(let opToken):
      return [opToken]
    case .qualified(schema: let schema, operator: let opToken):
      return [
        .operator, .joiner,
        .leftParenthesis, .joiner,
        .identifier(schema), .joiner, .dot, .joiner, opToken,
        .joiner, .rightParenthesis,
      ]
    case .and:
      return [.and]
    case .or:
      return [.or]
    case .not:
      return [.not]
    }
  }

  public static let lessThan: Operator = .single(.lessThan)

  public static let greaterThan: Operator = .single(.greaterThan)

  public static let lessThanOrEqualTo: Operator = .single(.lessThanOrEqualTo)

  public static let greaterThanOrEqualTo: Operator = .single(.greaterThanOrEqualTo)

  public static let equalTo: Operator = .single(.equalTo)

  public static let notEqualTo: Operator = .single(.notEqualTo)

  public static let plus: Operator = .single(.plus)

  public static let minus: Operator = .single(.minus)

  public static let multiply: Operator = .single(.multiply)

  public static let divide: Operator = .single(.divide)

  public static let modulo: Operator = .single(.modulo)

  public static let exponent: Operator = .single(.exponent)

  public static let squareRoot: Operator = .single(.squareRoot)

  public static let cubeRoot: Operator = .single(.cubeRoot)

  public static let absoluteValue: Operator = .single(.absoluteValue)

  public static let bitwiseAnd: Operator = .single(.bitwiseAnd)

  public static let bitwiseOr: Operator = .single(.bitwiseOr)

  public static let bitwiseExclusiveOr: Operator = .single(.bitwiseExclusiveOr)

  public static let bitwiseNot: Operator = .single(.bitwiseNot)

  public static let bitwiseShiftLeft: Operator = .single(.bitwiseShiftLeft)

  public static let bitwiseShiftRight: Operator = .single(.bitwiseShiftRight)
}

/// A type that represents a binary infix operator invocation.
public struct BinaryInfixOperatorInvocation: SQLTokenSequence {
  /// Left-hand side expression.
  public var left: any SQLTokenSequence

  public var `operator`: Operator

  /// Right-hand side expression.
  public var right: any SQLTokenSequence

  public var tokens: [SQLToken] {
    return left.tokens + self.operator.tokens + right.tokens
  }

  public init(_ left: any SQLTokenSequence, _ `operator`: Operator, _ right: any SQLTokenSequence) {
    self.left = left
    self.operator = `operator`
    self.right = right
  }
}

/// A type that represents a unary prfeix operator invocation.
public struct UnaryPrefixOperatorInvocation: SQLTokenSequence {
  public var `operator`: Operator

  public var expression: any SQLTokenSequence

  public var tokens: [SQLToken] {
    let omitParentheses = switch expression {
    case let singleToken as SingleToken where !singleToken.isNegativeNumeric: true
    default: false
    }

    var tokens = self.operator.tokens
    tokens.append(.joiner)
    if omitParentheses {
      tokens.append(contentsOf: expression)
    } else {
      tokens.append(contentsOf: expression.parenthesized)
    }
    return tokens
  }

  public init(_ `operator`: Operator, _ expression: any SQLTokenSequence) {
    self.operator = `operator`
    self.expression = expression
  }
}
