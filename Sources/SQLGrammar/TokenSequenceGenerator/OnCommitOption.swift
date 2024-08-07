/* *************************************************************************************************
 OnCommitOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to controll the behavior of temporary tables at the end of a transaction block.
/// This is described as `OnCommitOption` in "gram.y".
public enum OnCommitOption: TokenSequence {
  case drop
  case deleteRows
  case preserveRows

  public final class Tokens: TokenSequence {
    public let tokens: Array<Token>
    private init(_ tokens: Array<Token>) { self.tokens = tokens }

    public static let drop: Tokens = .init([.on, .commit, .drop])

    public static let deleteRows: Tokens = .init([.on, .commit, .delete, .rows])

    public static let preserveRows: Tokens = .init([.on, .commit, .preserve, .rows])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .drop:
      return .drop
    case .deleteRows:
      return .deleteRows
    case .preserveRows:
      return .preserveRows
    }
  }
}
