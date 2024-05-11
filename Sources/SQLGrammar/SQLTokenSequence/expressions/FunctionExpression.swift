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
