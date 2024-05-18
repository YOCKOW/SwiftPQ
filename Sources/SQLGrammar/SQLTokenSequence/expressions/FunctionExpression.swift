/* *************************************************************************************************
 FunctionExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing an expression described as `func_expr` in "gram.y"
public protocol FunctionExpression: ProductionExpression {}

/// A type representing an expression of function that does not accept WINDOW functions directly
/// and is described as `func_expr_windowless` in "gram.y"
public protocol WindowlessFunctionExpression: Expression {}

/// A type representing a special expression that is considered to be function and
/// described as `func_expr_common_subexpr` in "gram.y"
public protocol CommonFunctionSubexpression: FunctionExpression, WindowlessFunctionExpression {}

/// A type representing JSON aggregate function,
/// that is described as `json_aggregate_func` in "gram.y"
public protocol JSONAggregateFunctionExpression: WindowlessFunctionExpression {}

/// A type that represents `func_application` described in "gram.y".
public struct FunctionApplication: WindowlessFunctionExpression {
  public struct ArgumentList: SQLTokenSequence {
    public enum AggregatePattern: LosslessTokenConvertible {
      case all
      case distinct

      public var token: SQLToken {
        switch self {
        case .all:
          return .all
        case .distinct:
          return .distinct
        }
      }

      public init?(_ token: SQLToken) {
        switch token {
        case .all:
          self = .all
        case .distinct:
          self = .distinct
        default:
          return nil
        }
      }
    }

    public let aggregate: AggregatePattern?

    public let arguments: FunctionArgumentList?

    public let variadicArgument: FunctionArgumentExpression?

    public let orderBy: SortClause?

    public var tokens: JoinedSQLTokenSequence {
      var sequences: [any SQLTokenSequence] = []

      if let aggregate = self.aggregate {
        sequences.append(aggregate.asSequence)
      }

      if let arguments = self.arguments {
        sequences.append(arguments)
      }

      if let variadicArgument = self.variadicArgument {
        assert(aggregate == nil, "Variadic argument not allowed with aggregate pattern.")
        if arguments != nil {
          sequences.append(commaSeparator)
        }
        sequences.append(SingleToken(.variadic))
        sequences.append(variadicArgument)
      }

      if let orderBy = self.orderBy {
        assert(arguments != nil || variadicArgument != nil, "Sort clause alone not allowed.")
        sequences.append(orderBy)
      }

      return JoinedSQLTokenSequence(sequences)
    }

    /// Create a list described as `func_arg_list opt_sort_clause`.
    @inlinable public init(
      arguments: FunctionArgumentList,
      orderBy: SortClause? = nil
    ) {
      self.aggregate = nil
      self.arguments = arguments
      self.variadicArgument = nil
      self.orderBy = orderBy
    }

    /// Create a list described as `VARIADIC func_arg_expr opt_sort_clause`.
    @inlinable public init(
      variadicArgument: FunctionArgumentExpression,
      orderBy: SortClause? = nil
    ) {
      self.aggregate = nil
      self.arguments = nil
      self.variadicArgument = variadicArgument
      self.orderBy = orderBy
    }

    /// Create a list described as `func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause`.
    @inlinable public init(
      arguments: FunctionArgumentList,
      variadicArgument: FunctionArgumentExpression,
      orderBy: SortClause? = nil
    ) {
      self.aggregate = nil
      self.arguments = arguments
      self.variadicArgument = variadicArgument
      self.orderBy = orderBy
    }

    /// Create a list described as `[ALL | DISTINCT] func_arg_list opt_sort_clause`.
    @inlinable public init(
      aggregate: AggregatePattern,
      arguments: FunctionArgumentList,
      orderBy: SortClause? = nil
    ) {
      self.aggregate = aggregate
      self.arguments = arguments
      self.variadicArgument = nil
      self.orderBy = orderBy
    }
  }

  /// Enclosed expression(s) as argument list.
  public enum Arguments: SQLTokenSequence {
    case any

    case list(ArgumentList)

    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .any:
        return JoinedSQLTokenSequence(SingleToken(.asterisk))
      case .list(let argumentList):
        return argumentList.tokens
      }
    }
  }

  /// Function name.
  public let functionName: FunctionName

  public let arguments: Arguments?

  public var tokens: JoinedSQLTokenSequence {
    if let arguments {
      return functionName.followedBy(parenthesized: arguments)
    }
    return functionName.followedBy(parenthesized: SingleToken.joiner)
  }

  public init(_ functionName: FunctionName, arguments: Arguments?) {
    self.functionName = functionName
    self.arguments = arguments
  }

  /// Create a function applilcation described as `func_name '(' func_arg_list opt_sort_clause ')'`.
  @inlinable public init(
    _ functionName: FunctionName,
    arguments: FunctionArgumentList,
    orderBy: SortClause? = nil
  ) {
    self.init(
      functionName,
      arguments: .list(ArgumentList(arguments: arguments, orderBy: orderBy))
    )
  }

  /// Create a function applilcation described as
  /// `func_name '(' VARIADIC func_arg_expr opt_sort_clause ')'`.
  @inlinable public init(
    _ functionName: FunctionName,
    variadicArgument: FunctionArgumentExpression,
    orderBy: SortClause? = nil
  ) {
    self.init(
      functionName,
      arguments: .list(ArgumentList(variadicArgument: variadicArgument, orderBy: orderBy))
    )
  }

  /// Create a function applilcation described as
  /// `func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause ')'`.
  @inlinable public init(
    _ functionName: FunctionName,
    arguments: FunctionArgumentList,
    variadicArgument: FunctionArgumentExpression,
    orderBy: SortClause? = nil
  ) {
    self.init(
      functionName,
      arguments: .list(
        ArgumentList(arguments: arguments, variadicArgument: variadicArgument, orderBy: orderBy)
      )
    )
  }

  /// Create a function applilcation described as
  /// `func_name '(' [ALL | DISTINCT] func_arg_list opt_sort_clause ')'`.
  @inlinable public init(
    _ functionName: FunctionName,
    aggregate: ArgumentList.AggregatePattern,
    arguments: FunctionArgumentList,
    orderBy: SortClause? = nil
  ) {
    self.init(
      functionName,
      arguments: .list(
        ArgumentList(aggregate: aggregate, arguments: arguments, orderBy: orderBy)
      )
    )
  }
}

/// A kind of function call described as
/// `func_application within_group_clause filter_clause over_clause` in "gram.y".
/// It's a union of [Aggregate Expression](https://www.postgresql.org/docs/16/sql-expressions.html#SYNTAX-AGGREGATES)
/// and [Window Function Call](https://www.postgresql.org/docs/16/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS).
public struct AggregateWindowFunction: FunctionExpression, ValueExpression {
  public let application: FunctionApplication

  public let withinGroup: WithinGroupClause?

  public let filter: FilterClause?

  public let window: OverClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(application, withinGroup, filter, window)
  }

  public init(
    application: FunctionApplication,
    withinGroup: WithinGroupClause? = nil,
    filter: FilterClause? = nil,
    window: OverClause? = nil
  ) {
    self.application = application
    self.withinGroup = withinGroup
    self.filter = filter
    self.window = window
  }
}

// MARK: - CommonFunctionSubexpression a.k.a. func_expr_common_subexpr

private final class _CollationFor: Segment {
  let tokens: Array<SQLToken> = [.collation, .for]
  static let collationFor: _CollationFor = .init()
}

/// A representation of `COLLATION FOR '(' a_expr ')'`.
public struct CollationFor<Expression>: CommonFunctionSubexpression where Expression: GeneralExpression {
  public let expression: Expression

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(_CollationFor.collationFor, expression.parenthesized)
  }

  public init(_ expression: Expression) {
    self.expression = expression
  }
}

/// A representation of `CURRENT_DATE`.
public final class CurrentDate: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.currentDate]
  public static let currentDate: CurrentDate = .init()
}

/// A type of function that returns value related to the current date and time.
public protocol CurrentTimeExpression: CommonFunctionSubexpression {
  var function: SQLToken { get }
  var precision: UnsignedIntegerConstantExpression? { get }
}
extension CurrentTimeExpression {
  public var tokens: JoinedSQLTokenSequence {
    if let precision = self.precision {
      return function.asSequence.followedBy(parenthesized: precision)
    }
    return JoinedSQLTokenSequence(function.asSequence)
  }
}

/// A representation of `CURRENT_TIME` or `CURRENT_TIME(precision)`
public struct CurrentTime: CurrentTimeExpression, CommonFunctionSubexpression {
  public let function: SQLToken = .currentTime
  public let precision: UnsignedIntegerConstantExpression?

  public init(precision: UnsignedIntegerConstantExpression? = nil) {
    self.precision = precision
  }
}

/// A representation of `CURRENT_TIMESTAMP` or `CURRENT_TIMESTAMP(precision)`
public struct CurrentTimestamp: CurrentTimeExpression, CommonFunctionSubexpression {
  public let function: SQLToken = .currentTimestamp
  public let precision: UnsignedIntegerConstantExpression?

  public init(precision: UnsignedIntegerConstantExpression? = nil) {
    self.precision = precision
  }
}

/// A representation of `LOCALTIME` or `LOCALTIME(precision)`
public struct LocalTime: CurrentTimeExpression, CommonFunctionSubexpression {
  public let function: SQLToken = .localtime
  public let precision: UnsignedIntegerConstantExpression?

  public init(precision: UnsignedIntegerConstantExpression? = nil) {
    self.precision = precision
  }
}

/// A representation of `LOCALTIMESTAMP` or `LOCALTIMESTAMP(precision)`
public struct LocalTimestamp: CurrentTimeExpression, CommonFunctionSubexpression {
  public let function: SQLToken = .localtimestamp
  public let precision: UnsignedIntegerConstantExpression?

  public init(precision: UnsignedIntegerConstantExpression? = nil) {
    self.precision = precision
  }
}

/// A representation of `CURRENT_ROLE`.
public final class CurrentRole: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.currentRole]
  public static let currentRole: CurrentDate = .init()
}

/// A representation of `CURRENT_USER`.
public final class CurrentUser: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.currentUser]
  public static let currentUser: CurrentDate = .init()
}

/// A representation of `SESSION_USER`.
public final class SessionUser: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.sessionUser]
  public static let sessionUser: CurrentDate = .init()
}

/// A representation of `SYSTEM_USER`.
public final class SystemUser: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.systemUser]
  public static let systemUser: CurrentDate = .init()
}

/// A representation of `USER`.
public final class User: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.user]
  public static let user: CurrentDate = .init()
}

/// A representation of `CURRENT_CATALOG`.
public final class CurrentCatalog: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.currentCatalog]
  public static let currentCatalog: CurrentDate = .init()
}

/// A representation of `CURRENT_SCHEMA`.
public final class CurrentSchema: CommonFunctionSubexpression {
  public let tokens: Array<SQLToken> = [.currentSchema]
  public static let currentSchema: CurrentDate = .init()
}

/// A representation of `CAST '(' a_expr AS Typename ')'`
public struct TypeCastFunction: CommonFunctionSubexpression, ValueExpression {
  public let value: any GeneralExpression

  public let typeName: TypeName

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.cast).followedBy(parenthesized: JoinedSQLTokenSequence([
      value,
      SingleToken(.as),
      typeName
    ] as [any SQLTokenSequence]))
  }

  public init(_ value: any GeneralExpression, `as` typeName: TypeName) {
    self.value = value
    self.typeName = typeName
  }
}

/// A function that is described as `EXTRACT '(' extract_list ')'`.
public struct ExtractFunction: CommonFunctionSubexpression {
  /// A token that selects what field to extract from the source value.
  /// It corresponds to `extract_arg` in "gram.y".
  public struct Field: LosslessTokenConvertible {
    public let token: SQLToken

    public init?(_ token: SQLToken) {
      switch token {
      case is SQLToken.Identifier:
        self.token = token
      case let keyword as SQLToken.Keyword:
        guard (
          keyword == .year ||
          keyword == .month ||
          keyword == .day ||
          keyword == .hour ||
          keyword == .minute ||
          keyword == .second
        ) else {
          return nil
        }
        self.token = keyword
      case is SQLToken.StringConstant:
        self.token = token
      default:
        return nil
      }
    }

    /// `YEAR`
    public static let year: Field = .init(.year)!

    /// `MONTH`
    public static let month: Field = .init(.month)!

    /// `DAY`
    public static let day: Field = .init(.day)!

    /// `HOUR`
    public static let hour: Field = .init(.hour)!

    /// `MINUTE`
    public static let minute: Field = .init(.minute)!

    /// `SECOND`
    public static let second: Field = .init(.second)!
  }

  /// A representation of `extract_list`.
  private struct _List: Segment {
    let field: Field
    let source: any GeneralExpression
    var tokens: JoinedSQLTokenSequence {
      return JoinedSQLTokenSequence([
        field.asSequence,
        SingleToken(.from),
        source,
      ] as [any SQLTokenSequence])
    }
  }

  private let _list: _List

  public var field: Field { return _list.field }

  public var source: any GeneralExpression { return _list.source }

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.extract).followedBy(parenthesized: _list)
  }

  /// Creates a sequence of tokens such as `EXTRACT(field FROM source)`.
  public init(field: Field, from source: any GeneralExpression) {
    self._list = _List(field: field, source: source)
  }
}

/// A representation of `NORMALIZE '(' a_expr ')'` or
/// `NORMALIZE '(' a_expr ',' unicode_normal_form ')'`.
public struct NormalizeFunction: CommonFunctionSubexpression {
  public let text: any GeneralExpression

  public let form: UnicodeNormalizationForm?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.normalize).followedBy(
      parenthesized: JoinedSQLTokenSequence.compacting(
        [
          text,
          form.map(SingleToken.init),
        ] as [(any SQLTokenSequence)?],
        separator: commaSeparator
      )
    )
  }

  public init(text: any GeneralExpression, form: UnicodeNormalizationForm? = nil) {
    self.text = text
    self.form = form
  }
}

/// A representation of `OVERLAY '(' overlay_list ')'` or `OVERLAY '(' func_arg_list_opt ')'`.
public struct OverlayFunction: CommonFunctionSubexpression {
  /// A representation of `overlay_list`.
  public struct List: SQLTokenSequence {
    public let targetText: any GeneralExpression

    public let replacementText: any GeneralExpression

    public let startIndex: any GeneralExpression

    public let length: (any GeneralExpression)?

    public var tokens: JoinedSQLTokenSequence {
      return .compacting([
        targetText,
        SingleToken(.placing),
        replacementText,
        SingleToken(.from),
        startIndex,
        length.map({ JoinedSQLTokenSequence([SingleToken(.for), $0] as [any SQLTokenSequence]) }),
      ] as [(any SQLTokenSequence)?])
    }

    public init(
      targetText: any GeneralExpression,
      replacementText: any GeneralExpression,
      startIndex: any GeneralExpression,
      length: (any GeneralExpression)?
    ) {
      self.targetText = targetText
      self.replacementText = replacementText
      self.startIndex = startIndex
      self.length = length
    }
  }

  private enum _Arguments: SQLTokenSequence {
    case list(List)
    case functionArgumentList(FunctionArgumentList?)

    var tokens: JoinedSQLTokenSequence {
      switch self {
      case .list(let list):
        return list.tokens
      case .functionArgumentList(let list):
        return list?.tokens ?? JoinedSQLTokenSequence()
      }
    }
  }

  private let _arguments: _Arguments

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.overlay).followedBy(parenthesized: _arguments)
  }

  public init(_ list: List) {
    self._arguments = .list(list)
  }

  public init(_ list: FunctionArgumentList?) {
    self._arguments = .functionArgumentList(list)
  }

  /// Creates an overlay function call such as
  /// `OVERLAY (targetText PLACING replacementText FROM startIndex FOR length)`.
  public init(
    targetText: any GeneralExpression,
    replacementText: any GeneralExpression,
    startIndex: any GeneralExpression,
    length: (any GeneralExpression)? = nil
  ) {
    let list = List(
      targetText: targetText,
      replacementText: replacementText,
      startIndex: startIndex,
      length: length
    )
    self._arguments = .list(list)
  }
}

/// A representation of `POSITION '(' position_list ')'`.
public struct PositionFunction: CommonFunctionSubexpression {
  public let substring: any RestrictedExpression

  public let text: any RestrictedExpression

  public var tokens: JoinedSQLTokenSequence {
    let list = JoinedSQLTokenSequence([
      substring,
      SingleToken(.in),
      text,
    ] as [any SQLTokenSequence])
    return SingleToken(.position).followedBy(parenthesized: list)
  }

  public init(_ substring: any RestrictedExpression, `in` text: any RestrictedExpression) {
    self.substring = substring
    self.text = text
  }
}

/// A representation of `SUBSTRING '(' substr_list ')'` or `SUBSTRING '(' func_arg_list_opt ')'`.
public struct SubstringFunction: CommonFunctionSubexpression {
  /// A representation of `substr_list`.
  public struct List: SQLTokenSequence {
    private enum _Pattern {
      case range(startIndex: (any GeneralExpression)?, length: (any GeneralExpression)?)
      case sqlRegularExpression(pattern: any GeneralExpression, escapeCharacter: any GeneralExpression)
    }

    public let targetText: any GeneralExpression

    private let _pattern: _Pattern

    public var startIndex: (any GeneralExpression)? {
      guard case .range(let startIndex, _) = _pattern else {
        return nil
      }
      return startIndex
    }

    public var length: (any GeneralExpression)? {
      guard case .range(_, let length) = _pattern else {
        return nil
      }
      return length
    }

    public var sqlRegularExpression: (any GeneralExpression)? {
      guard case .sqlRegularExpression(let pattern, _) = _pattern else {
        return nil
      }
      return pattern
    }

    public var sqlReqularExpressionEscapeCharacter: (any GeneralExpression)? {
      guard case .sqlRegularExpression(_, let escapeCharacter) = _pattern else {
        return nil
      }
      return escapeCharacter
    }

    public var tokens: JoinedSQLTokenSequence {
      var sequences: [any SQLTokenSequence] = [targetText]
      switch _pattern {
      case .range(let startIndex, let length):
        assert(startIndex != nil || length != nil, "Invalid range?!")
        if let startIndex {
          sequences.append(SingleToken(.from))
          sequences.append(startIndex)
        }
        if let length {
          sequences.append(SingleToken(.for))
          sequences.append(length)
        }
      case .sqlRegularExpression(let pattern, let escapeCharacter):
        sequences.append(contentsOf: [
          SingleToken(.similar),
          pattern,
          SingleToken(.escape),
          escapeCharacter,
        ] as [any SQLTokenSequence])
      }
      return JoinedSQLTokenSequence(sequences)
    }

    private init(targetText: any GeneralExpression, pattern: _Pattern) {
      self.targetText = targetText
      self._pattern = pattern
    }

    public init(
      targetText: any GeneralExpression,
      from startIndex: any GeneralExpression
    ) {
      self.init(targetText: targetText, pattern: .range(startIndex: startIndex, length: nil))
    }

    public init(
      targetText: any GeneralExpression,
      for length: any GeneralExpression
    ) {
      self.init(targetText: targetText, pattern: .range(startIndex: nil, length: length))
    }

    public init(
      targetText: any GeneralExpression,
      from startIndex: any GeneralExpression,
      for length: any GeneralExpression
    ) {
      self.init(targetText: targetText, pattern: .range(startIndex: startIndex, length: length))
    }

    public init(
      targetText: any GeneralExpression,
      similar pattern: any GeneralExpression,
      escape escapeCharacter: any GeneralExpression
    ) {
      self.init(
        targetText: targetText,
        pattern: .sqlRegularExpression(pattern: pattern, escapeCharacter: escapeCharacter)
      )
    }
  }

  private enum _Arguments: SQLTokenSequence {
    case list(List)
    case functionArgumentList(FunctionArgumentList?)

    var tokens: JoinedSQLTokenSequence {
      switch self {
      case .list(let list):
        return list.tokens
      case .functionArgumentList(let list):
        return list?.tokens ?? JoinedSQLTokenSequence()
      }
    }
  }

  private let _arguments: _Arguments

  public var list: List? {
    guard case .list(let list) = _arguments else { return nil }
    return list
  }

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.substring).followedBy(parenthesized: _arguments)
  }

  public init(_ list: List) {
    self._arguments = .list(list)
  }

  public init(_ list: FunctionArgumentList?) {
    self._arguments = .functionArgumentList(list)
  }

  /// Creates a function call such as `SUBSTRING(targetText FROM startIndex)`.
  @inlinable public init(
    targetText: any GeneralExpression,
    from startIndex: any GeneralExpression
  ) {
    self.init(List(targetText: targetText, from: startIndex))
  }

  /// Creates a function call such as `SUBSTRING(targetText FOR length)`.
  @inlinable public init(
    targetText: any GeneralExpression,
    for length: any GeneralExpression
  ) {
    self.init(List(targetText: targetText, for: length))
  }

  /// Creates a function call such as `SUBSTRING(targetText FROM startIndex FOR length)`.
  @inlinable public init(
    targetText: any GeneralExpression,
    from startIndex: any GeneralExpression,
    for length: any GeneralExpression
  ) {
    self.init(List(targetText: targetText, from: startIndex, for: length))
  }

  /// Creates a function call such as `SUBSTRING(targetText SIMILAR pattern ESCAPE escapeCharacter)`.
  @inlinable public init(
    targetText: any GeneralExpression,
    similar pattern: any GeneralExpression,
    escape escapeCharacter: any GeneralExpression
  ) {
    self.init(List(targetText: targetText, similar: pattern, escape: escapeCharacter))
  }
}

/// A representation of `TREAT '(' a_expr AS Typename ')'`
public struct TreatFunction: CommonFunctionSubexpression {
  public let value: any GeneralExpression

  public let typeName: TypeName

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.treat).followedBy(parenthesized: JoinedSQLTokenSequence([
      value,
      SingleToken(.as),
      typeName
    ] as [any SQLTokenSequence]))
  }

  public init(_ value: any GeneralExpression, `as` typeName: TypeName) {
    self.value = value
    self.typeName = typeName
  }
}

/// A representation `TRIM '(' [BOTH|LEADING|TRAILING] trim_list ')'`
public struct TrimFunction: CommonFunctionSubexpression {
  public enum TrimmingEnd: LosslessTokenConvertible {
    case leading
    case trailing
    case both

    public var token: SQLToken {
      switch self {
      case .leading:
        return .leading
      case .trailing:
        return .trailing
      case .both:
        return .both
      }
    }

    public init?(_ token: SQLToken) {
      switch token {
      case .leading:
        self = .leading
      case .trailing:
        self = .trailing
      case .both:
        self = .both
      default:
        return nil
      }
    }
  }

  /// A representation of `trim_list`.
  public struct List: SQLTokenSequence {
    private enum _Style {
      case trimFromTarget(any GeneralExpression, GeneralExpressionList)
      case from(GeneralExpressionList)
      case onlyList(GeneralExpressionList)
    }

    private let _style: _Style

    public var tokens: JoinedSQLTokenSequence {
      switch _style {
      case .trimFromTarget(let trimCharacters, let target):
        return JoinedSQLTokenSequence([
          trimCharacters,
          SingleToken(.from),
          target,
        ] as [any SQLTokenSequence])
      case .from(let list):
        return JoinedSQLTokenSequence(SingleToken(.from), list)
      case .onlyList(let list):
        return JoinedSQLTokenSequence(list)
      }
    }

    public var trimCharacters: GeneralExpressionList? {
      switch _style {
      case .trimFromTarget(let trimCharacters, _):
        return GeneralExpressionList(NonEmptyList<any GeneralExpression>(item: trimCharacters))
      case .from(let list), .onlyList(let list):
        return NonEmptyList<any GeneralExpression>(items: list.expressions.items.dropFirst()).map {
          GeneralExpressionList($0)
        }
      }
    }

    public var targetText: GeneralExpressionList {
      switch _style {
      case .trimFromTarget(_, let target):
        return target
      case .from(let list), .onlyList(let list):
        return GeneralExpressionList(
          NonEmptyList<any GeneralExpression>(item: list.expressions.first)
        )
      }
    }

    private init(style: _Style) {
      self._style = style
    }

    public init(trimCharacters: any GeneralExpression, targetText: GeneralExpressionList) {
      self._style = .trimFromTarget(trimCharacters, targetText)
    }

    public static func nonstandardSyntax(
      includeFromKeyword: Bool,
      arguments: GeneralExpressionList
    ) -> List {
      if includeFromKeyword {
        return .init(style: .from(arguments))
      }
      return .init(style: .onlyList(arguments))
    }
  }

  public let trimmingEnd: TrimmingEnd?

  private let _list: List

  public var trimCharacters: GeneralExpressionList? {
    return _list.trimCharacters
  }

  public var targetText: GeneralExpressionList {
    return _list.targetText
  }

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.trim).followedBy(parenthesized: JoinedSQLTokenSequence.compacting(
      trimmingEnd.map(SingleToken.init),
      _list
    ))
  }

  public init(trimmingEnd: TrimmingEnd? = nil, _ list: List) {
    self.trimmingEnd = trimmingEnd
    self._list = list
  }

  public init(
    trimmingEnd: TrimmingEnd? = nil,
    trimCharacters: any GeneralExpression,
    from targetText: GeneralExpressionList
  ) {
    self.init(
      trimmingEnd: trimmingEnd,
      List(trimCharacters: trimCharacters, targetText: targetText)
    )
  }

  /// Create a function call such as `TRIM(BOTH trimCharacters FROM targetText)`.
  public init(
    trimmingEnd: TrimmingEnd? = nil,
    trimCharacters: StringConstantExpression,
    from targetText: StringConstantExpression
  ) {
    self.init(
      trimmingEnd: trimmingEnd,
      trimCharacters: trimCharacters,
      from: GeneralExpressionList([targetText])
    )
  }
}

/// A representation of `NULLIF '(' a_expr ',' a_expr ')'`
public struct NullIfFunction: CommonFunctionSubexpression {
  public let leftValue: any GeneralExpression
  public let rightValue: any GeneralExpression

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.nullif).followedBy(parenthesized: [leftValue, rightValue].joinedByCommas())
  }

  public init(_ leftValue: any GeneralExpression, _ rightValue: any GeneralExpression) {
    self.leftValue = leftValue
    self.rightValue = rightValue
  }
}

/// A representation of `COALESCE '(' expr_list ')'`.
public struct CoalesceFunction: CommonFunctionSubexpression {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.coalesce).followedBy(parenthesized: expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }

  public init(_ expressions: NonEmptyList<any GeneralExpression>) {
    self.expressions = GeneralExpressionList(expressions)
  }
}

/// A representation of `GREATEST '(' expr_list ')'`.
public struct GreatestFunction: CommonFunctionSubexpression {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.greatest).followedBy(parenthesized: expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }

  public init(_ expressions: NonEmptyList<any GeneralExpression>) {
    self.expressions = GeneralExpressionList(expressions)
  }
}

/// A representation of `LEAST '(' expr_list ')'`.
public struct LeastFunction: CommonFunctionSubexpression {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.least).followedBy(parenthesized: expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }

  public init(_ expressions: NonEmptyList<any GeneralExpression>) {
    self.expressions = GeneralExpressionList(expressions)
  }
}

/// A representation of `XMLCONCAT '(' expr_list ')'`.
public struct XMLConcatenateFunction: CommonFunctionSubexpression {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlconcat).followedBy(parenthesized: expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }

  public init(_ expressions: NonEmptyList<any GeneralExpression>) {
    self.expressions = GeneralExpressionList(expressions)
  }
}

/// A representation of `XMLELEMENT ( ... )`.
public struct XMLElementFunction: CommonFunctionSubexpression {
  public let name: ColumnLabel

  private var _nameTokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.name), SingleToken(name))
  }

  public let attributes: XMLAttributeList?

  private var _attributesTokens: JoinedSQLTokenSequence? {
    return attributes.map {
      return SingleToken(.xmlattributes).followedBy(parenthesized: $0)
    }
  }

  public let contents: GeneralExpressionList?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlelement).followedBy(parenthesized: JoinedSQLTokenSequence.compacting(
      _nameTokens,
      _attributesTokens,
      contents,
      separator: commaSeparator
    ))
  }

  public init(
    name: ColumnLabel,
    attributes: XMLAttributeList? = nil,
    contents: GeneralExpressionList? = nil
  ) {
    self.name = name
    self.attributes = attributes
    self.contents = contents
  }
}

/// A function call descrebed as `XMLEXISTS '(' c_expr xmlexists_argument ')'` in "gram.y".
public struct XMLExistsFunction: CommonFunctionSubexpression {
  /// An expression in the XML Query language.
  ///
  /// - Note: PostgreSQL allows only an XPath 1.0 expression.
  ///         See [D.3.1. Queries Are Restricted to XPath 1.0](https://www.postgresql.org/docs/current/xml-limits-conformance.html#FUNCTIONS-XML-LIMITS-XPATH1).
  public let xmlQuery: any ProductionExpression

  public let argument: XMLPassingArgument

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlexists).followedBy(parenthesized: JoinedSQLTokenSequence([
      xmlQuery,
      argument,
    ] as [any SQLTokenSequence]))
  }

  public init(xmlQuery: any ProductionExpression, argument: XMLPassingArgument) {
    self.xmlQuery = xmlQuery
    self.argument = argument
  }

  public init(xmlQuery: StringConstantExpression, argument: XMLPassingArgument) {
    self.xmlQuery = xmlQuery
    self.argument = argument
  }
}

/// A function call described as `XMLFOREST '(' xml_attribute_list ')'` in "gram.y".
public struct XMLForestFunction: CommonFunctionSubexpression {
  /// Names and contents.
  public let elements: XMLAttributeList

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlforest).followedBy(parenthesized: elements)
  }

  public init(_ elements: XMLAttributeList) {
    self.elements = elements
  }
}

/// A function call describeda as
/// `XMLPARSE '(' document_or_content a_expr xml_whitespace_option ')'` in "gram.y".
public struct XMLParseFunction: CommonFunctionSubexpression {
  public let option: XMLOption

  public let text: any GeneralExpression

  public let whitespaceOption: XMLWhitespaceOption?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlparse).followedBy(parenthesized: JoinedSQLTokenSequence.compacting([
      SingleToken(option),
      text,
      whitespaceOption,
    ] as [(any SQLTokenSequence)?]))
  }

  public init(
    _ option: XMLOption,
    text: any GeneralExpression,
    whitespaceOption: XMLWhitespaceOption? = nil
  ) {
    self.option = option
    self.text = text
    self.whitespaceOption = whitespaceOption
  }

  public init(
    _ option: XMLOption,
    text: StringConstantExpression,
    whitespaceOption: XMLWhitespaceOption? = nil
  ) {
    self.option = option
    self.text = text
    self.whitespaceOption = whitespaceOption
  }
}

/// A function call consisted of tokens such as `XMLPI ( NAME someName [, content] )`.
public struct XMLPIFunction: CommonFunctionSubexpression {
  public let name: ColumnLabel

  public let content: (any GeneralExpression)?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlpi).followedBy(parenthesized: JoinedSQLTokenSequence.compacting([
      SingleToken(.name),
      SingleToken(name),
      content.map({
        JoinedSQLTokenSequence([commaSeparator, $0] as [any SQLTokenSequence])
      }),
    ] as [(any SQLTokenSequence)?]))
  }

  public init(name: ColumnLabel, content: (any GeneralExpression)?) {
    self.name = name
    self.content = content
  }

  public init(name: ColumnLabel, content: StringConstantExpression) {
    self.name = name
    self.content = content
  }
}

/// A function call described as `XMLROOT '(' a_expr ',' xml_root_version opt_xml_root_standalone ')'` in "gram.y".
public struct XMLRootFunction: CommonFunctionSubexpression {
  /// A type corresponding to `xml_root_version` in "gram.y".
  public enum Version: Segment {
    case version(any GeneralExpression)
    case noValue

    private final class _NoValue: Segment {
      let tokens: Array<SQLToken> = [.version, .no, .value]
      static let noValue: _NoValue = .init()
    }
    private static let _noValueTokens: JoinedSQLTokenSequence = .init(_NoValue.noValue)

    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .version(let expr):
        return JoinedSQLTokenSequence([SingleToken(.version), expr] as [any SQLTokenSequence])
      case .noValue:
        return XMLRootFunction.Version._noValueTokens
      }
    }
  }

  /// A value that indicates whether or not the document is standalone.
  /// It is described as `opt_xml_root_standalone` in "gram.y".
  public enum Standalone: Segment {
    case yes
    case no
    case noValue

    private static let _yesTokens: Array<SQLToken> = [.standalone, .yes]
    private static let _noTokens: Array<SQLToken> = [.standalone, .no]
    private static let _noValueTokens: Array<SQLToken> = [.standalone, .no, .value]

    public var tokens: Array<SQLToken> {
      switch self {
      case .yes:
        return Standalone._yesTokens
      case .no:
        return Standalone._noTokens
      case .noValue:
        return Standalone._noValueTokens
      }
    }
  }

  public let xml: (any GeneralExpression)

  public let version: Version

  public let standalone: Standalone?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlroot).followedBy(parenthesized: JoinedSQLTokenSequence.compacting([
      xml,
      commaSeparator,
      version,
      standalone.map({ JoinedSQLTokenSequence(commaSeparator, $0) }),
    ] as [(any SQLTokenSequence)?]))
  }

  public init(xml: any GeneralExpression, version: Version, standalone: Standalone?) {
    self.xml = xml
    self.version = version
    self.standalone = standalone
  }

  public init(
    xml: any GeneralExpression,
    version: StringConstantExpression,
    standalone: Standalone? = nil
  ) {
    self.xml = xml
    self.version = .version(version)
    self.standalone = standalone
  }
}

/// A function call described as`XMLSERIALIZE '(' document_or_content a_expr AS SimpleTypename xml_indent_option ')'` in "gram.y".
public struct XMLSerializeFunction: CommonFunctionSubexpression {
  /// An option of indentation, described as `xml_indent_option` in "gram.y".
  public enum IndentOption: Segment {
    case indent
    case noIndent

    private static let _indentTokens: Array<SQLToken> = [.indent]
    private static let _noIndentTokens: Array<SQLToken> = [.no, .indent]

    public var tokens: Array<SQLToken> {
      switch self {
      case .indent:
        return IndentOption._indentTokens
      case .noIndent:
        return IndentOption._noIndentTokens
      }
    }
  }

  public let option: XMLOption

  public let xml: any GeneralExpression

  public let typeName: any SimpleTypeName

  public let indentOption: IndentOption?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.xmlserialize).followedBy(parenthesized: JoinedSQLTokenSequence.compacting([
      option.asSequence,
      xml,
      SingleToken(.as),
      typeName,
      indentOption,
    ] as [(any SQLTokenSequence)?]))
  }

  public init(
    _ option: XMLOption,
    xml: any GeneralExpression,
    `as` typeName: any SimpleTypeName,
    indentOption: IndentOption? = nil
  ) {
    self.option = option
    self.xml = xml
    self.typeName = typeName
    self.indentOption = indentOption
  }
}

/// A representation of `JSON_OBJECT ( ... )`.
public struct JSONObjectFunction: CommonFunctionSubexpression {
  public struct Arguments: SQLTokenSequence {
    public let keyValuePairs: JSONKeyValuePairList?

    public let nullOption: JSONObjectConstructorNullOption?

    public let keyUniquenessOption: JSONKeyUniquenessOption?

    public let outputType: JSONOutputTypeClause?

    public var tokens: JoinedSQLTokenSequence {
      return .compacting(keyValuePairs, nullOption, keyUniquenessOption, outputType)
    }

    public init(
      keyValuePairs: JSONKeyValuePairList,
      nullOption: JSONObjectConstructorNullOption? = nil,
      keyUniquenessOption: JSONKeyUniquenessOption? = nil,
      outputType: JSONOutputTypeClause? = nil
    ) {
      self.keyValuePairs = keyValuePairs
      self.nullOption = nullOption
      self.keyUniquenessOption = keyUniquenessOption
      self.outputType = outputType
    }

    public init(outputType: JSONOutputTypeClause?) {
      self.keyValuePairs = nil
      self.nullOption = nil
      self.keyUniquenessOption = nil
      self.outputType = outputType
    }
  }

  private enum _ArgumentList {
    case arguments(Arguments)
    case functionArgumentList(FunctionArgumentList)
  }

  private let _argumentList: _ArgumentList

  public var tokens: JoinedSQLTokenSequence {
    switch _argumentList {
    case .arguments(let arguments):
      return SingleToken(.jsonObject).followedBy(parenthesized: arguments)
    case .functionArgumentList(let argumentList):
      return SingleToken(.jsonObject).followedBy(parenthesized: argumentList)
    }
  }

  public var arguments: Arguments? {
    guard case .arguments(let arguments) = _argumentList else {
      return nil
    }
    return arguments
  }

  public var keyValuePairs: JSONKeyValuePairList? {
    return arguments?.keyValuePairs
  }

  public var nullOption: JSONObjectConstructorNullOption? {
    return arguments?.nullOption
  }

  public var keyUniquenessOption: JSONKeyUniquenessOption? {
    return arguments?.keyUniquenessOption
  }

  public var outputType: JSONOutputTypeClause? {
    return arguments?.outputType
  }

  public init(_ arguments: Arguments) {
    self._argumentList = .arguments(arguments)
  }

  public init(argumentList: FunctionArgumentList) {
    self._argumentList = .functionArgumentList(argumentList)
  }

  public init(
    keyValuePairs: JSONKeyValuePairList,
    nullOption: JSONObjectConstructorNullOption? = nil,
    keyUniquenessOption: JSONKeyUniquenessOption? = nil,
    outputType: JSONOutputTypeClause? = nil
  ) {
    self._argumentList = .arguments(
      Arguments(
        keyValuePairs: keyValuePairs,
        nullOption: nullOption,
        keyUniquenessOption: keyUniquenessOption,
        outputType: outputType
      )
    )
  }

  public init(outputType: JSONOutputTypeClause?) {
    self._argumentList = .arguments(Arguments(outputType: outputType))
  }
}

/// A representation of `JSON_ARRAY( ... )`.
public struct JSONArrayFunction: CommonFunctionSubexpression {
  private enum _Arguments: SQLTokenSequence {
    case valueList(
      JSONValueExpressionList,
      nullOption: JSONArrayConstructorNullOption?,
      outputType: JSONOutputTypeClause?
    )
    case selectStatement(
      any BareSelectStatement,
      format: JSONFormatClause?,
      outputType: JSONOutputTypeClause?
    )
    case outputType(JSONOutputTypeClause?)

    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .valueList(let list, let nullOption, let outputType):
        return .compacting(list, nullOption, outputType)
      case .selectStatement(let query, let format, let outputType):
        return .compacting([query, format, outputType] as [(any SQLTokenSequence)?])
      case .outputType(let outputType):
        return .compacting(outputType)
      }
    }
  }

  private let _arguments: _Arguments

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.jsonArray).followedBy(parenthesized: _arguments)
  }

  public var values: JSONValueExpressionList? {
    guard case .valueList(let list, _, _) = _arguments else { return nil }
    return list
  }

  public var nullOption: JSONArrayConstructorNullOption? {
    guard case .valueList(_, let nullOption, _) = _arguments else { return nil }
    return nullOption
  }

  public var outputType: JSONOutputTypeClause? {
    switch _arguments {
    case .valueList(_, _, let outputType):
      return outputType
    case .selectStatement(_, _, let outputType):
      return outputType
    case .outputType(let outputType):
      return outputType
    }
  }

  public var query: (any BareSelectStatement)? {
    guard case .selectStatement(let bareSelectStatement, _,_) = _arguments else {
      return nil
    }
    return bareSelectStatement
  }

  public var format: JSONFormatClause? {
    guard case .selectStatement(_, let format, _) = _arguments else {
      return nil
    }
    return format
  }

  public init(
    values: JSONValueExpressionList,
    nullOption: JSONArrayConstructorNullOption? = nil,
    outputType: JSONOutputTypeClause? = nil
  ) {
    self._arguments = .valueList(values, nullOption: nullOption, outputType: outputType)
  }

  public init(
    query: any BareSelectStatement,
    format: JSONFormatClause? = nil,
    outputType: JSONOutputTypeClause? = nil
  ) {
    self._arguments = .selectStatement(query, format: format, outputType: outputType)
  }

  public init(outputType: JSONOutputTypeClause?) {
    self._arguments = .outputType(outputType)
  }
}


// MARK: END OF CommonFunctionSubexpression a.k.a. func_expr_common_subexpr -

// MARK: - JSONAggregateFunctionExpression a.k.a. json_aggregate_func

/// A `JSON_OBJECTAGG` function call.
public struct JSONObjectAggregateFunction: JSONAggregateFunctionExpression {
  public let keyValuePair: JSONKeyValuePair

  public let nullOption: JSONObjectConstructorNullOption?

  public let keyUniquenessOption: JSONKeyUniquenessOption?

  public let outputType: JSONOutputTypeClause?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.jsonObjectagg).followedBy(parenthesized: JoinedSQLTokenSequence.compacting(
      keyValuePair,
      nullOption,
      keyUniquenessOption,
      outputType
    ))
  }

  public init(
    keyValuePair: JSONKeyValuePair,
    nullOption: JSONObjectConstructorNullOption? = nil,
    keyUniquenessOption: JSONKeyUniquenessOption? = nil,
    outputType: JSONOutputTypeClause? = nil
  ) {
    self.keyValuePair = keyValuePair
    self.nullOption = nullOption
    self.keyUniquenessOption = keyUniquenessOption
    self.outputType = outputType
  }
}

/// A `JSON_ARRAYAGG` function call.
public struct JSONArrayAggregateFunction: JSONAggregateFunctionExpression {
  public let value: JSONValueExpression

  public let orderBy: JSONArrayAggregateSortClause?

  public let nullOption: JSONArrayConstructorNullOption?

  public let outputType: JSONOutputTypeClause?

  public var tokens: JoinedSQLTokenSequence {
    return SingleToken(.jsonArrayagg).followedBy(parenthesized: JoinedSQLTokenSequence.compacting(
      value,
      orderBy,
      nullOption,
      outputType
    ))
  }

  public init(
    value: JSONValueExpression,
    orderBy: JSONArrayAggregateSortClause? = nil,
    nullOption: JSONArrayConstructorNullOption? = nil,
    outputType: JSONOutputTypeClause? = nil
  ) {
    self.value = value
    self.orderBy = orderBy
    self.nullOption = nullOption
    self.outputType = outputType
  }
}

// MARK: END OF JSONAggregateFunctionExpression a.k.a. json_aggregate_func -
