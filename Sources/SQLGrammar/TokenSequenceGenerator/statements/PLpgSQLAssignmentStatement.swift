/* *************************************************************************************************
 PLpgSQLAssignmentStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of PL/pgSQL Assignment statement described as `PLAssignStmt` in "gram.y".
public struct PLpgSQLAssignmentStatement: TokenSequenceGenerator {
  public struct Variable: TokenSequenceGenerator {
    /// Representation of `plassign_target` in "gram.y".
    public enum Target: CustomTokenConvertible, Sendable {
      case identifier(ColumnIdentifier)
      case parameter(Token.PositionalParameter)

      @inlinable
      public var token: Token {
        switch self {
        case .identifier(let columnIdentifier):
          return columnIdentifier.token
        case .parameter(let positionalParameter):
          return positionalParameter
        }
      }
    }

    public let target: Target

    public let indirection: Indirection?

    @inlinable
    public var tokens: JoinedTokenSequence {
      return .compacting(target.asSequence, indirection)
    }

    public init(_ identifier: ColumnIdentifier, indirection: Indirection? = nil) {
      self.target = .identifier(identifier)
      self.indirection = indirection
    }

    public init(_ parameter: Token.PositionalParameter, indirection: Indirection? = nil) {
      self.target = .parameter(parameter)
      self.indirection = indirection
    }
  }

  /// Representation of `plassign_equals` in "gram.y".
  public enum Operator: CustomTokenConvertible, Sendable {
    case colonEquals
    case equalTo

    public var token: Token.Operator {
      switch self {
      case .colonEquals:
        return .colonEquals
      case .equalTo:
        return .equalTo
      }
    }
  }

  public let variable: Variable

  public let `operator`: Operator

  public let expression: PLpgSQLExpression

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(variable, self.operator.asSequence, expression)
  }

  public init(variable: Variable, `operator`: Operator = .colonEquals, expression: PLpgSQLExpression) {
    self.variable = variable
    self.operator = `operator`
    self.expression = expression
  }
}
