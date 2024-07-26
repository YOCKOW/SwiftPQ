/* *************************************************************************************************
 Parenthesized.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public final class LeftParenthesis: Segment {
  public let tokens: [Token] = [.leftParenthesis, .joiner]
  static let leftParenthesis: LeftParenthesis = .init()
}

public final class RightParenthesis: Segment {
  public let tokens: [Token] = [.joiner, .rightParenthesis]
  public static let rightParenthesis: RightParenthesis = .init()
}

/// Representation of parenthesized sequence of tokens.
public struct Parenthesized<EnclosedTokens>: TokenSequence where EnclosedTokens: TokenSequenceGenerator {
  public let enclosedTokens: EnclosedTokens

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(
      LeftParenthesis.leftParenthesis,
      enclosedTokens,
      RightParenthesis.rightParenthesis
    )
  }

  public init(_ tokens: EnclosedTokens) {
    self.enclosedTokens = tokens
  }
}

extension TokenSequenceGenerator {
  public var parenthesized: Parenthesized<Self> {
    return Parenthesized<Self>(self)
  }
}

extension TokenSequenceGenerator {
  public func followedBy<T>(
    parenthesized expression: T
  ) -> JoinedTokenSequence where T: TokenSequenceGenerator {
    return JoinedTokenSequence(self, expression.parenthesized, separator: [.joiner])
  }
}

/// A statement that can be also a statement even if parenthesized.
public protocol ParenthesizableStatement: Statement {}

extension Parenthesized: TopLevelStatement, Statement,
                         ParenthesizableStatement where EnclosedTokens: ParenthesizableStatement {}

public protocol ParenthesizablePreparableStatement: PreparableStatement, ParenthesizableStatement {}
extension Parenthesized: PreparableStatement,
                         ParenthesizablePreparableStatement where EnclosedTokens: ParenthesizablePreparableStatement {}

/// An expression that can be also an expression even if parenthesized.
public protocol ParenthesizableExpression: Expression {}

extension Parenthesized: Expression,
                         ParenthesizableExpression where EnclosedTokens: ParenthesizableExpression {}
