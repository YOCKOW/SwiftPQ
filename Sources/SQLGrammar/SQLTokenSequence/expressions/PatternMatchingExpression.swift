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
  associatedtype Operator: TokenSequenceGenerator
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

extension GeneralExpression {
  @inlinable
  public func like(
    _ pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) -> LikeExpression {
    return .init(string: self, like: pattern, escape: escapeCharacter)
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
    notLike pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) {
    self.string = string
    self.pattern = pattern
    self.escapeCharacter = escapeCharacter
  }
}

extension GeneralExpression {
  @inlinable
  public func notLike(
    _ pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) -> NotLikeExpression {
    return .init(string: self, notLike: pattern, escape: escapeCharacter)
  }
}

/// Representation of `ILIKE` expression described as `a_expr ILIKE a_expr [ESCAPE a_expr]` in "gram.y".
public struct CaseInsensitiveLikeExpression: PatternMatchingGeneralExpression {
  public final class Operator: Segment {
    public let tokens: Array<SQLToken> = [.ilike]
    private init() {}
    public static let iLike: Operator = .init()
  }

  public let string: any GeneralExpression

  public let `operator`: Operator = .iLike

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

extension GeneralExpression {
  @inlinable
  public func caseInsensitiveLike(
    _ pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) -> CaseInsensitiveLikeExpression {
    return .init(string: self, like: pattern, escape: escapeCharacter)
  }
}

/// Representation of `NOT ILIKE` expression described as `a_expr NOT_LA ILIKE a_expr [ESCAPE a_expr]` in "gram.y".
public struct NotCaseInsensitiveLikeExpression: PatternMatchingGeneralExpression {
  public final class Operator: Segment {
    public let tokens: Array<SQLToken> = [.not, .ilike]
    private init() {}
    public static let notIlike: Operator = .init()
  }

  public let string: any GeneralExpression

  public let `operator`: Operator = .notIlike

  public let pattern: any GeneralExpression

  public let escapeCharacter: Optional<any GeneralExpression>

  public init(
    string: any GeneralExpression,
    notLike pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) {
    self.string = string
    self.pattern = pattern
    self.escapeCharacter = escapeCharacter
  }
}

extension GeneralExpression {
  @inlinable
  public func notCaseInsensitiveLike(
    _ pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) -> NotCaseInsensitiveLikeExpression {
    return .init(string: self, notLike: pattern, escape: escapeCharacter)
  }
}

/// Representation of `SIMILAR TO` expression described as `a_expr SIMILAR TO a_expr [ESCAPE a_expr]` in "gram.y".
public struct SimilarToExpression: PatternMatchingGeneralExpression {
  public final class Operator: Segment {
    public let tokens: Array<SQLToken> = [.similar, .to]
    private init() {}
    public static let similarTo: Operator = .init()
  }

  public let string: any GeneralExpression

  public let `operator`: Operator = .similarTo

  public let pattern: any GeneralExpression

  public let escapeCharacter: Optional<any GeneralExpression>

  public init(
    string: any GeneralExpression,
    similarTo pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) {
    self.string = string
    self.pattern = pattern
    self.escapeCharacter = escapeCharacter
  }
}

extension GeneralExpression {
  @inlinable
  public func similarTo(
    _ pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) -> SimilarToExpression {
    return .init(string: self, similarTo: pattern, escape: escapeCharacter)
  }
}

/// Representation of `NOT SIMILAR TO` expression described as `a_expr NOT_LA SIMILAR TO a_expr [ESCAPE a_expr]` in "gram.y".
public struct NotSimilarToExpression: PatternMatchingGeneralExpression {
  public final class Operator: Segment {
    public let tokens: Array<SQLToken> = [.not, .similar, .to]
    private init() {}
    public static let notSimilarTo: Operator = .init()
  }

  public let string: any GeneralExpression

  public let `operator`: Operator = .notSimilarTo

  public let pattern: any GeneralExpression

  public let escapeCharacter: Optional<any GeneralExpression>

  public init(
    string: any GeneralExpression,
    notSimilarTo pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) {
    self.string = string
    self.pattern = pattern
    self.escapeCharacter = escapeCharacter
  }
}

extension GeneralExpression {
  @inlinable
  public func notSimilarTo(
    _ pattern: any GeneralExpression,
    escape escapeCharacter: Optional<any GeneralExpression> = nil
  ) -> NotSimilarToExpression {
    return .init(string: self, notSimilarTo: pattern, escape: escapeCharacter)
  }
}
