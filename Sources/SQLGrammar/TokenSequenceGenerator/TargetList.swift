/* *************************************************************************************************
 TargetList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing an element that is described as `target_el` in "gram.y".
public struct TargetElement: TokenSequenceGenerator {
  private enum _ElementType {
    case expressionAsColumnLabel(any GeneralExpression, ColumnLabel)
    case expressionWithBareColumnLabel(any GeneralExpression, BareColumnLabel)
    case expression(any GeneralExpression)
    case all
  }

  private let _type: _ElementType

  public var tokens: JoinedSQLTokenSequence {
    switch _type {
    case .expressionAsColumnLabel(let expression, let columnLabel):
      return JoinedSQLTokenSequence([
        expression,
        SingleToken(.as),
        columnLabel.asSequence
      ] as Array<any TokenSequenceGenerator>)
    case .expressionWithBareColumnLabel(let expression, let bareColumnLabel):
      return JoinedSQLTokenSequence([
        expression,
        bareColumnLabel.asSequence
      ] as Array<any TokenSequenceGenerator>)
    case .expression(let expression):
      return JoinedSQLTokenSequence([expression])
    case .all:
      return JoinedSQLTokenSequence(SingleToken(.asterisk))
    }
  }

  private init(_ type: _ElementType) {
    self._type = type
  }

  /// Create a target element of `a_expr AS ColLabel`.
  public init<Expr>(
    _ expression: Expr,
    `as` outputName: ColumnLabel
  ) where Expr: GeneralExpression {
    self.init(.expressionAsColumnLabel(expression, outputName))
  }

  /// Create a target element of `a_expr BareColLabel`.
  public init<Expr>(
    _ expression: Expr,
    _ outputName: BareColumnLabel
  ) where Expr: GeneralExpression {
    self.init(.expressionWithBareColumnLabel(expression, outputName))
  }

  public init<Expr>(_ expression: Expr) where Expr: GeneralExpression {
    self.init(.expression(expression))
  }

  /// Create a target element of `*`.
  public static let all: TargetElement = .init(.all)
}

/// A list of targets, that is described as `target_list` in "gram.y".
public struct TargetList: TokenSequenceGenerator,
                          InitializableWithNonEmptyList,
                          ExpressibleByArrayLiteral {
  public var elements: NonEmptyList<TargetElement>

  public var tokens: JoinedSQLTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<TargetElement>) {
    self.elements = elements
  }
}
