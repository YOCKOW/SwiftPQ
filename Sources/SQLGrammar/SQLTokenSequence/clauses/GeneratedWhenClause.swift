/* *************************************************************************************************
 GeneratedWhenClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to determine how explicitly user-specified values are handled in `INSERT` and `UPDATE`
///  commands. This is described as `generated_when` in "gram.y".
public enum GeneratedWhenClause: Clause {
  case always
  case byDefault

  public struct Tokens: SQLTokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }
    public static let always: Tokens = .init([.always])
    public static let byDefault: Tokens = .init([.by, .default])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .always:
      return .always
    case .byDefault:
      return .byDefault
    }
  }

  @inlinable
  public func makeIterator() -> Tokens.Iterator {
    return tokens.makeIterator()
  }
}
