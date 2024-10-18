/* *************************************************************************************************
 FunctionArgumentExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An expression that represents a function argument,
///  that is described as `func_arg_expr` in "gram.y".
public struct FunctionArgumentExpression: Expression {
  private enum _Notation: Sendable {
    /// `a_expr`
    case positional(any GeneralExpression)

    /// `param_name EQUALS_GREATER a_expr`
    case named(ParameterName, value: any GeneralExpression)

    /// `param_name COLON_EQUALS a_expr`
    case legacyNamed(ParameterName, value: any GeneralExpression)
  }

  private let _notation: _Notation

  public var tokens: JoinedTokenSequence {
    switch _notation {
    case .positional(let generalExpression):
      return JoinedTokenSequence([generalExpression])
    case .named(let name, let value):
      return JoinedTokenSequence([
        name,
        SingleToken(Token.Operator.arrowSign),
        value
      ] as [any TokenSequenceGenerator])
    case .legacyNamed(let name, let value):
      return JoinedTokenSequence([
        name,
        SingleToken(Token.Operator.colonEquals),
        value
      ] as [any TokenSequenceGenerator])
    }
  }

  /// Create an expression that is the same as the given expression.
  public init<E>(_ expression: E) where E: GeneralExpression {
    self._notation = .positional(expression)
  }

  /// Create an expression in named notation such as `name => expression`.
  public init<E>(name: ParameterName, value: E) where E: GeneralExpression {
    self._notation = .named(name, value: value)
  }
}

extension GeneralExpression {
  public var asFunctionArgument: FunctionArgumentExpression {
    return .init(self)
  }

  public func asFunctionArgumentNamed(_ name: ParameterName) -> FunctionArgumentExpression {
    return .init(name: name, value: self)
  }
}

/// A list of function arguments. Described as `func_arg_list` in "gram.y".
public struct FunctionArgumentList: TokenSequenceGenerator {
  public var arguments: NonEmptyList<FunctionArgumentExpression>

  public init(_ arguments: NonEmptyList<FunctionArgumentExpression>) {
    self.arguments = arguments
  }

  public init(_ expressionList: GeneralExpressionList) {
    self.arguments = expressionList.expressions.map({ $0.asFunctionArgument })
  }

  public init?(_ arguments: KeyValuePairs<ParameterName?, any GeneralExpression>) {
    if arguments.isEmpty {
      return nil
    }
    self.arguments = NonEmptyList<FunctionArgumentExpression>(
      items: arguments.reduce(into: Array<FunctionArgumentExpression>()) {
        if let name = $1.key {
          $0.append($1.value.asFunctionArgumentNamed(name))
        } else {
          $0.append($1.value.asFunctionArgument)
        }
      }
    )!
  }

  public var tokens: JoinedTokenSequence {
    return arguments.joinedByCommas()
  }
}

