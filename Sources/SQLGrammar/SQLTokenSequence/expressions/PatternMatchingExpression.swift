/* *************************************************************************************************
 PatternMatchingExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type of pattern matching expression.
///
/// Reference: [§9.7. Pattern Matching](https://www.postgresql.org/docs/current/functions-matching.html).
public protocol PatternMatchingExpression: Expression {}

/// A type of pattern matching expression that is expected to be one of
/// `[NOT] LIKE`, `[NOT] ILIKE`, or `[NOT] SIMILAR TO`.
public protocol PatternMatchingGeneralExpression: PatternMatchingExpression, GeneralExpression {
  /// An operator of pattern matching.
  associatedtype Operator: SQLTokenSequence
  var string: any GeneralExpression { get }
  var `operator`: Operator { get }
  var pattern: any GeneralExpression { get }
  var escapeCharacter: Optional<any GeneralExpression> { get }
}

extension PatternMatchingGeneralExpression where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return .compacting([
      self.string,
      self.operator,
      self.pattern,
      self.escapeCharacter.map({ JoinedSQLTokenSequence([SingleToken(.escape), $0]) })
    ])
  }
}

/// Representation of `LIKE` expression described as `a_expr LIKE a_expr [ESCAPE a_expr]` in "gram.y".
public struct LikeExpression: PatternMatchingGeneralExpression {
  public final class Operator: Segment {
    public let tokens: Array<SQLToken> = [.like]
    private init() {}
    public static let like: Operator = .init()
  }

  public let string: any GeneralExpression

  public let `operator`: Operator = .like

  public let pattern: any GeneralExpression

  public let escapeCharacter: Optional<any GeneralExpression>

  public init(
    string: any GeneralExpression,
    like pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) {
    self.string = string
    self.pattern = pattern
    self.escapeCharacter = escapeCharacter
  }
}

/// Representation of `NOT LIKE` expression described as `a_expr NOT_LA LIKE a_expr [ESCAPE a_expr]` in "gram.y".
public struct NotLikeExpression: PatternMatchingGeneralExpression {
  public final class Operator: Segment {
    public let tokens: Array<SQLToken> = [.not, .like]
    private init() {}
    public static let notLike: Operator = .init()
  }

  public let string: any GeneralExpression

  public let `operator`: Operator = .notLike

  public let pattern: any GeneralExpression

  public let escapeCharacter: Optional<any GeneralExpression>

  public init(
    string: any GeneralExpression,
    like pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) {
    self.string = string
    self.pattern = pattern
    self.escapeCharacter = escapeCharacter
  }
}
