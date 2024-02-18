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

extension Array where Element == any SQLTokenSequence {
  public func joined<S>(separator: S = Array<SQLToken>([.joiner, .comma])) -> Array<SQLToken> where S: Sequence, S.Element == SQLToken {
    var result: [SQLToken] = []
    for (ii, exp) in self.enumerated() {
      result.append(contentsOf: exp)
      if ii < self.count - 1 {
        result.append(contentsOf: separator)
      }
    }
    return result
  }
}

public struct SingleToken: SQLTokenSequence {
  public var token: SQLToken

  internal init(_ token: SQLToken) {
    self.token = token
  }

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
    return .init(try .positionalParameter(position))
  }

  public static func identifier(_ string: String, forceQuoting: Bool = false) -> SingleToken {
    return .init(.identifier(string, forceQuoting: forceQuoting))
  }

  public static func integer<T>(_ integer: T) -> SingleToken where T: FixedWidthInteger {
    return .init(.numeric(integer))
  }

  public static func float<T>(_ float: T) -> SingleToken where T: BinaryFloatingPoint & CustomStringConvertible {
    return .init(.numeric(float))
  }

  public static func string(_ string: String) -> SingleToken {
    return .init(.string(string))
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

public struct FunctionCall: SQLTokenSequence {
  /// A name of the function.
  public var name: FunctionName

  /// Arguments of the function.
  public var arguments: [any SQLTokenSequence]

  public var tokens: [SQLToken] {
    var tokens = name.tokens
    tokens.append(contentsOf: [.joiner, .leftParenthesis, .joiner])

    for (ii, argument) in arguments.enumerated() {
      tokens.append(contentsOf: argument)
      if ii < arguments.count - 1 {
        tokens.append(contentsOf: [.joiner, .comma])
      }
    }

    tokens.append(contentsOf: [.joiner, .rightParenthesis])
    return tokens
  }

  public init(name: FunctionName, arguments: [any SQLTokenSequence]) {
    self.name = name
    self.arguments = arguments
  }

  public init<each T: SQLTokenSequence>(name: FunctionName, argument: repeat each T)  {
    var arguments: [any SQLTokenSequence] = []
    repeat (arguments.append(each argument))
    self.init(name: name, arguments: arguments)
  }
}

/// A type that represents `FILTER (WHERE filter_expression)`
public struct FilterClause: SQLTokenSequence {
  public var filter: any SQLTokenSequence

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [.filter, .leftParenthesis, .joiner, .where]
    tokens.append(contentsOf: filter.tokens)
    tokens.append(contentsOf: [.joiner, .rightParenthesis])
    return tokens
  }

  public init(_ filter: any SQLTokenSequence) {
    self.filter = filter
  }
}

/// A type that represents an aggregate expression.
public struct AggregateExpression: SQLTokenSequence {
  public enum AggregatePattern {
    case all(expressions: [any SQLTokenSequence], orderBy: SortClause? = nil, filter: FilterClause? = nil)
    case distinct(expressions: [any SQLTokenSequence], orderBy: SortClause? = nil, filter: FilterClause? = nil)
    case any(filter: FilterClause? = nil)
    case orderedSet(expressions: [any SQLTokenSequence], withinGroup: SortClause, filter: FilterClause? = nil)

    fileprivate var _tokens: [SQLToken] {
      var tokens: [SQLToken] = []

      func __append(expressions: [any SQLTokenSequence]) {
        for (ii, expression) in expressions.enumerated() {
          tokens.append(contentsOf: expression)
          if ii < expressions.count - 1 {
            tokens.append(contentsOf: [.joiner, .comma])
          }
        }
      }

      switch self {
      case .all(let expressions, let orderBy, let filter):
        tokens.append(contentsOf: [.leftParenthesis, .joiner, .all])
        __append(expressions: expressions)
        orderBy.map({ tokens.append(contentsOf: $0) })
        tokens.append(contentsOf: [.joiner, .rightParenthesis])
        filter.map({ tokens.append(contentsOf: $0) })
      case .distinct(let expressions, let orderBy, let filter):
        tokens.append(contentsOf: [.leftParenthesis, .joiner, .distinct])
        __append(expressions: expressions)
        orderBy.map({ tokens.append(contentsOf: $0) })
        tokens.append(contentsOf: [.joiner, .rightParenthesis])
        filter.map({ tokens.append(contentsOf: $0) })
      case .any(let filter):
        tokens.append(contentsOf: [.leftParenthesis, .joiner, .asterisk, .joiner, .rightParenthesis])
        filter.map({ tokens.append(contentsOf: $0) })
      case .orderedSet(let expressions, let withinGroup, let filter):
        tokens.append(contentsOf: [.leftParenthesis, .joiner])
        __append(expressions: expressions)
        tokens.append(contentsOf: [.joiner, .rightParenthesis])
        tokens.append(contentsOf: [.within, .group, .leftParenthesis, .joiner])
        tokens.append(contentsOf: withinGroup)
        tokens.append(contentsOf: [.joiner, .rightParenthesis])
        filter.map({ tokens.append(contentsOf: $0) })
      }
      return tokens
    }
  }

  public var name: AggregateName

  public var pattern: AggregatePattern

  public var tokens: [SQLToken] {
    var tokens = name.tokens
    tokens.append(.joiner)
    tokens.append(contentsOf: pattern._tokens)
    return tokens
  }

  public init(name: AggregateName, pattern: AggregatePattern) {
    self.name = name
    self.pattern = pattern
  }
}


/// A type that represents a name of window.
public struct WindowName: SQLTokenSequence {
  /// A name of schema.
  public var schema: String?

  /// A name of the window.
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

/// Representation of frame clause used in window function calls.
public struct FrameClause: SQLTokenSequence {
  public enum Mode {
    case range
    case rows
    case groups

    fileprivate var token: SQLToken {
      switch self {
      case .range:
        return .range
      case .rows:
        return .rows
      case .groups:
        return .groups
      }
    }
  }

  public enum Bound {
    case unboundedPreceding
    case preceding(offset: any SQLTokenSequence)
    case currentRow
    case following(offset: any SQLTokenSequence)
    case unboundedFollowing

    fileprivate var tokens: [SQLToken] {
      switch self {
      case .unboundedPreceding:
        return [.unbounded, .preceding]
      case .preceding(let offset):
        return offset.tokens + [.preceding]
      case .currentRow:
        return [.current, .row]
      case .following(let offset):
        return offset.tokens + [.following]
      case .unboundedFollowing:
        return [.unbounded, .following]
      }
    }
  }

  public enum Exclusion {
    case currentRow
    case group
    case ties
    case noOthers

    fileprivate var tokens: [SQLToken] {
      switch self {
      case .currentRow:
        return [.exclude, .current, .row]
      case .group:
        return [.exclude, .group]
      case .ties:
        return [.exclude, .ties]
      case .noOthers:
        return [.exclude, .no, .others]
      }
    }
  }

  public var mode: Mode

  public var start: Bound

  public var end: Bound?

  public var exclusion: Exclusion?

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [mode.token]

    if let end {
      tokens.append(.between)
      tokens.append(contentsOf: start.tokens)
      tokens.append(.and)
      tokens.append(contentsOf: end.tokens)
    } else {
      tokens.append(contentsOf: start.tokens)
    }

    exclusion.map({ tokens.append(contentsOf: $0.tokens) })

    return tokens
  }

  public init(mode: Mode, start: Bound, end: Bound? = nil, exclusion: Exclusion? = nil) {
    self.mode = mode
    self.start = start
    self.end = end
    self.exclusion = exclusion
  }
}

public struct WindowDefinition: SQLTokenSequence {
  public var existingWindowName: WindowName?

  public var partitionBy: [any SQLTokenSequence]?

  public var orderBy: WindowDefinitionSortClause?

  public var frame: FrameClause?

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    existingWindowName.map({ tokens.append(contentsOf: $0) })
    partitionBy.map({
      tokens.append(contentsOf: [.partition, .by])
      tokens.append(contentsOf: $0.joined())
    })
    orderBy.map({ tokens.append(contentsOf: $0) })
    frame.map({ tokens.append(contentsOf: $0) })
    return tokens
  }

  public init(
    existingWindowName: WindowName?,
    partitionBy: [any SQLTokenSequence]?,
    orderBy: WindowDefinitionSortClause?,
    frame: FrameClause?
  ) {
    self.existingWindowName = existingWindowName
    self.partitionBy = partitionBy
    self.orderBy = orderBy
    self.frame = frame
  }
}

/// Representation of a window function call
public struct WindowFunctionCall: SQLTokenSequence {
  public enum Argument {
    case expressions([any SQLTokenSequence])
    case any
  }

  public enum Window {
    case name(WindowName)
    case definition(WindowDefinition)
  }

  public var name: FunctionName

  public var argument: Argument

  public var filter: FilterClause?

  public var window: Window

  public var tokens: [SQLToken] {
    var tokens = name.tokens

    tokens.append(contentsOf: [.joiner, .leftParenthesis, .joiner])
    switch argument {
    case .expressions(let expressions):
      tokens.append(contentsOf: expressions.joined())
    case .any:
      tokens.append(.asterisk)
    }
    tokens.append(contentsOf: [.joiner, .rightParenthesis])

    filter.map({ tokens.append(contentsOf: $0) })

    tokens.append(.over)
    switch window {
    case .name(let windowName):
      tokens.append(contentsOf: windowName)
    case .definition(let windowDefinition):
      tokens.append(contentsOf: windowDefinition.parenthesized)
    }

    return tokens
  }
}

/// Representation of type-cast expression.
public struct TypeCast: SQLTokenSequence {
  public var expression: any SQLTokenSequence

  public var type: DataType

  public var tokens: [SQLToken] {
    var tokens: [SQLToken] = [.cast, .leftParenthesis]
    tokens.append(contentsOf: expression)
    tokens.append(.as)
    tokens.append(contentsOf: type.tokens)
    tokens.append(.rightParenthesis)
    return tokens
  }

  public init(expression: any SQLTokenSequence, type: DataType) {
    self.expression = expression
    self.type = type
  }
}

/// Representation of a collation expression.
public struct CollationExpression: SQLTokenSequence {
  /// An expression to be collated.
  public var expression: any SQLTokenSequence

  public var collation: CollationName

  public var tokens: [SQLToken] {
    var tokens = expression.tokens
    tokens.append(.collate)
    tokens.append(contentsOf: collation)
    return tokens
  }

  public init(expression: any SQLTokenSequence, collation: CollationName) {
    self.expression = expression
    self.collation = collation
  }
}

/// Representation of an array constructor.
public struct ArrayConstructor: SQLTokenSequence {
  /// Initial elements (i.e. arguments of the constructor).
  public var elements: [any SQLTokenSequence]

  private func _tokens(inArrayConstructor: Bool) -> [SQLToken] {
    var tokens: [SQLToken] = []
    if !inArrayConstructor {
      tokens.append(contentsOf: [.array, .joiner])
    }
    tokens.append(contentsOf: [.leftSquareBracket, .joiner])
    for (ii, element) in elements.enumerated() {
      if case let arrayConstructor as ArrayConstructor = element {
        tokens.append(contentsOf: arrayConstructor._tokens(inArrayConstructor: true))
      } else {
        tokens.append(contentsOf: element)
      }
      if ii < elements.count - 1 {
        tokens.append(contentsOf: [.joiner, .comma])
      }
    }
    tokens.append(contentsOf: [.joiner, .rightSquareBracket])
    return tokens
  }

  public var tokens: [SQLToken] {
    return _tokens(inArrayConstructor: false)
  }

  public init(_ elements: [any SQLTokenSequence]) {
    self.elements = elements
  }

  public init<each T>(_ element: repeat each T) where repeat each T: SQLTokenSequence {
    var elements: [any SQLTokenSequence] = []
    repeat (elements.append(each element))
    self.init(elements)
  }
}

/// Representation of a row constructor.
public struct RowConstructor: SQLTokenSequence {
  /// Elements of the row.
  public var elements: [any SQLTokenSequence]

  public var tokens: [SQLToken] {
    return [.row, .joiner, .leftParenthesis, .joiner] + elements.joined() + [.joiner, .rightParenthesis]
  }

  public init(_ elements: [any SQLTokenSequence]) {
    self.elements = elements
  }

  public init<each T>(_ element: repeat each T) where repeat each T: SQLTokenSequence {
    var elements: [any SQLTokenSequence] = []
    repeat (elements.append(each element))
    self.init(elements)
  }
}


public enum SequenceNumberGeneratorOption: SQLTokenSequence {
  case `as`(DataType)
  case increment(by: Int)
  case min(value: Int?)
  case max(value: Int?)
  case start(with: Int)
  case cache(Int)
  case cycle
  case noCycle
  case owned(by: ColumnReference?)

  public var tokens: [SQLToken] {
    switch self {
    case .as(let dataType):
      return [.as] + dataType.tokens
    case .increment(let int):
      return [.increment, .by, .numeric(int)]
    case .min(let value):
      if let value {
        return [.minvalue, .numeric(value)]
      }
      return [.no, .minvalue]
    case .max(let value):
      if let value {
        return [.maxvalue, .numeric(value)]
      }
      return [.no, .maxvalue]
    case .start(let int):
      return [.start, .with, .numeric(int)]
    case .cache(let int):
      return [.cache, .numeric(int)]
    case .cycle:
      return [.cycle]
    case .noCycle:
      return [.no, .cycle]
    case .owned(let owner):
      if let owner {
        return [.owned, .by] + owner.tokens
      }
      return [.owned, .by, .none]
    }
  }
}
