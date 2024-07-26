/* *************************************************************************************************
 Is(Not)DistinctFromExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private final class _IsDistinctFrom: Segment {
  let tokens: Array<Token> = [.is, .distinct, .from]
  private init() {}
  static let isDistinctFrom: _IsDistinctFrom = .init()
}

private final class _IsNotDistinctFrom: Segment {
  let tokens: Array<Token> = [.is, .not, .distinct, .from]
  private init() {}
  static let isNotDistinctFrom: _IsNotDistinctFrom = .init()
}

/// Representation of `IS DISTINCT FROM` predicate.
public struct IsDistinctFromExpression<Left, Right>: Expression where Left: Expression,
                                                                      Right: Expression {
  public let left: Left

  public let right: Right

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(left, _IsDistinctFrom.isDistinctFrom, right)
  }

  public init(_ left: Left, _ right: Right) {
    self.left = left
    self.right = right
  }
}
extension IsDistinctFromExpression: RecursiveExpression where Left: RecursiveExpression,
                                                              Right: RecursiveExpression {}
extension IsDistinctFromExpression: GeneralExpression where Left: GeneralExpression,
                                                            Right: GeneralExpression {}
extension IsDistinctFromExpression: RestrictedExpression where Left: RestrictedExpression,
                                                               Right: RestrictedExpression {}
extension RecursiveExpression {
  public func isDistinctFrom<OtherExpr>(
    _ otherExpression: OtherExpr
  ) -> IsDistinctFromExpression<Self, OtherExpr> where OtherExpr: Expression {
    return .init(self, otherExpression)
  }
}

/// Representation of `IS NOT DISTINCT FROM` predicate.
public struct IsNotDistinctFromExpression<Left, Right>: Expression where Left: Expression,
                                                                      Right: Expression {
  public let left: Left

  public let right: Right

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(left, _IsNotDistinctFrom.isNotDistinctFrom, right)
  }

  public init(_ left: Left, _ right: Right) {
    self.left = left
    self.right = right
  }
}
extension IsNotDistinctFromExpression: RecursiveExpression where Left: RecursiveExpression,
                                                                 Right: RecursiveExpression {}
extension IsNotDistinctFromExpression: GeneralExpression where Left: GeneralExpression,
                                                               Right: GeneralExpression {}
extension IsNotDistinctFromExpression: RestrictedExpression where Left: RestrictedExpression,
                                                                  Right: RestrictedExpression {}
extension RecursiveExpression {
  public func isNotDistinctFrom<OtherExpr>(
    _ otherExpression: OtherExpr
  ) -> IsNotDistinctFromExpression<Self, OtherExpr> where OtherExpr: Expression {
    return .init(self, otherExpression)
  }
}
