/* *************************************************************************************************
 Parenthesized.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public final class LeftParenthesis: Segment {
  public let tokens: [SQLToken] = [.leftParenthesis, .joiner]
  static let leftParenthesis: LeftParenthesis = .init()
}

public final class RightParenthesis: Segment {
  public let tokens: [SQLToken] = [.joiner, .rightParenthesis]
  public static let rightParenthesis: RightParenthesis = .init()
}

/// Representation of parenthesized sequence of tokens.
public struct Parenthesized<EnclosedTokens>: SQLTokenSequence where EnclosedTokens: SQLTokenSequence {
  public let enclosedTokens: EnclosedTokens

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      LeftParenthesis.leftParenthesis,
      enclosedTokens,
      RightParenthesis.rightParenthesis
    )
  }

  public init(_ tokens: EnclosedTokens) {
    self.enclosedTokens = tokens
  }
}

extension SQLTokenSequence {
  public var parenthesized: Parenthesized<Self> {
    return Parenthesized<Self>(self)
  }
}
