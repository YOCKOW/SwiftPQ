/* *************************************************************************************************
 TemporarinessOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to be used when a table is created. This is described as `OptTemp` in "gram.y".
public enum TemporarinessOption: TokenSequence {
  case temporary
  case temp
  case localTemporary
  case localTemp
  case globalTemporary
  case globalTemp
  case unlogged

  public final class Tokens: TokenSequence {
    public let tokens: Array<SQLToken>
    private init(_ tokens: Array<SQLToken>) { self.tokens = tokens }

    public static let temporary: Tokens = .init([.temporary])
    public static let temp: Tokens = .init([.temp])
    public static let localTemporary: Tokens = .init([.local, .temporary])
    public static let localTemp: Tokens = .init([.local, .temp])
    public static let globalTemporary: Tokens = .init([.global, .temporary])
    public static let globalTemp: Tokens = .init([.global, .temp])
    public static let unlogged: Tokens = .init([.unlogged])
  }

  @inlinable
  public var tokens: Tokens {
    switch self {
    case .temporary:
      return .temporary
    case .temp:
      return .temp
    case .localTemporary:
      return .localTemporary
    case .localTemp:
      return .localTemp
    case .globalTemporary:
      return .globalTemporary
    case .globalTemp:
      return .globalTemp
    case .unlogged:
      return .unlogged
    }
  }
}
