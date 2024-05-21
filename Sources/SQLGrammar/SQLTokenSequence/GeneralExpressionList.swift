/* *************************************************************************************************
 GeneralExpressionList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A list of general expressions, that is described as `expr_list` in "gram.y".
public struct GeneralExpressionList: SQLTokenSequence, ExpressibleByArrayLiteral {
  public var expressions: NonEmptyList<any GeneralExpression>

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    return expressions.map({ $0 as any SQLTokenSequence }).joinedByCommas()
  }

  public init(_ expressions: NonEmptyList<any GeneralExpression>) {
    self.expressions = expressions
  }

  public init<FirstExpr, each OptionalExpr>(
    _ firstExpression: FirstExpr, _ optionalExpression: repeat each OptionalExpr
  ) where FirstExpr: GeneralExpression, repeat each OptionalExpr: GeneralExpression {
    self.expressions = .init(item: firstExpression)
    repeat (self.expressions.append(each optionalExpression))
  }

  public init(arrayLiteral elements: (any GeneralExpression)...) {
    guard let nonEmptyExprs = NonEmptyList<any GeneralExpression>(items: elements) else {
      fatalError("\(Self.self): No expressions?!")
    }
    self.init(nonEmptyExprs)
  }
}
