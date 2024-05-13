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

// TODO: Implement a type for `POSITION '(' position_list ')'`
// TODO: Implement a type for `SUBSTRING '(' substr_list ')'`
// TODO: Implement a type for `SUBSTRING '(' func_arg_list_opt ')'`
// TODO: Implement a type for `TREAT '(' a_expr AS Typename ')'`
// TODO: Implement a type for `TRIM '(' BOTH trim_list ')'`
// TODO: Implement a type for `TRIM '(' LEADING trim_list ')'`
// TODO: Implement a type for `TRIM '(' TRAILING trim_list ')'`
// TODO: Implement a type for `TRIM '(' trim_list ')'`
// TODO: Implement a type for `NULLIF '(' a_expr ',' a_expr ')'`
// TODO: Implement a type for `COALESCE '(' expr_list ')'`
// TODO: Implement a type for `GREATEST '(' expr_list ')'`
// TODO: Implement a type for `LEAST '(' expr_list ')'`
// TODO: Implement a type for `XMLCONCAT '(' expr_list ')'`
// TODO: Implement a type for `XMLELEMENT '(' NAME_P ColLabel ')'`
// TODO: Implement a type for `XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ')'`
// TODO: Implement a type for `XMLELEMENT '(' NAME_P ColLabel ',' expr_list ')'`
// TODO: Implement a type for `XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ',' expr_list ')'`
// TODO: Implement a type for `XMLEXISTS '(' c_expr xmlexists_argument ')'`
// TODO: Implement a type for `XMLFOREST '(' xml_attribute_list ')'`
// TODO: Implement a type for `XMLPARSE '(' document_or_content a_expr xml_whitespace_option ')'`
// TODO: Implement a type for `XMLPI '(' NAME_P ColLabel ')'`
// TODO: Implement a type for `XMLPI '(' NAME_P ColLabel ',' a_expr ')'`
// TODO: Implement a type for `XMLROOT '(' a_expr ',' xml_root_version opt_xml_root_standalone ')'`
// TODO: Implement a type for `XMLSERIALIZE '(' document_or_content a_expr AS SimpleTypename xml_indent_option ')'`
// TODO: Implement a type for `JSON_OBJECT '(' func_arg_list ')'`
// TODO: Implement a type for `JSON_OBJECT '(' json_name_and_value_list json_object_constructor_null_clause_opt json_key_uniqueness_constraint_opt json_output_clause_opt ')'`
// TODO: Implement a type for `JSON_OBJECT '(' json_output_clause_opt ')'`
// TODO: Implement a type for `JSON_ARRAY '(' json_value_expr_list json_array_constructor_null_clause_opt json_output_clause_opt ')'`
// TODO: Implement a type for `JSON_ARRAY '(' select_no_parens json_format_clause_opt json_output_clause_opt ')'`
// TODO: Implement a type for `JSON_ARRAY '(' json_output_clause_opt ')'`


// MARK: END OF CommonFunctionSubexpression a.k.a. func_expr_common_subexpr -
