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
    public enum Target: CustomTokenConvertible {
      case identifier(ColumnIdentifier)
      case parameter(SQLToken.PositionalParameter)

      @inlinable
      public var token: SQLToken {
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
    public var tokens: JoinedSQLTokenSequence {
      return .compacting(target.asSequence, indirection)
    }

    public init(_ identifier: ColumnIdentifier, indirection: Indirection? = nil) {
      self.target = .identifier(identifier)
      self.indirection = indirection
    }

    public init(_ parameter: SQLToken.PositionalParameter, indirection: Indirection? = nil) {
      self.target = .parameter(parameter)
      self.indirection = indirection
    }
  }

  /// Representation of `plassign_equals` in "gram.y".
  public enum Operator: CustomTokenConvertible {
    case colonEquals
    case equalTo

    public var token: SQLToken.Operator {
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

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(variable, self.operator.asSequence, expression)
  }

  public init(variable: Variable, `operator`: Operator = .colonEquals, expression: PLpgSQLExpression) {
    self.variable = variable
    self.operator = `operator`
    self.expression = expression
  }
}
