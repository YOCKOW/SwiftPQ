/* *************************************************************************************************
 GeneralExpressionList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A list of general expressions, that is described as `expr_list` in "gram.y".
public struct GeneralExpressionList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public var expressions: NonEmptyList<any GeneralExpression>

  @inlinable
  public var expressionCount: Int {
    return expressions.count
  }

  @inlinable
  public var firstExpression: any GeneralExpression {
    return expressions.first
  }

  @inlinable
  public var lastExpression: any GeneralExpression {
    return expressions.last
  }

  @inlinable
  public var tokens: JoinedTokenSequence {
    return expressions.map({ $0 as any TokenSequenceGenerator }).joinedByCommas()
  }

  public init(_ expressions: NonEmptyList<any GeneralExpression>) {
    self.expressions = expressions
  }

  public init<FirstExpr, each OptionalExpr>(
    _ firstExpression: FirstExpr, _ optionalExpression: repeat each OptionalExpr
  ) where FirstExpr: GeneralExpression,
          repeat each OptionalExpr: GeneralExpression {
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
