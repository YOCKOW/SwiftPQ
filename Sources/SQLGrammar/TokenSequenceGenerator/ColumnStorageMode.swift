/* *************************************************************************************************
 ColumnStorageMode.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// The storage mode for the column that is described as `column_storage` in "gram.y".
public struct ColumnStorageMode: TokenSequenceGenerator {
  public enum ModeName: CustomTokenConvertible {
    case identifier(ColumnIdentifier)
    case `default`

    @inlinable
    public var token: Token {
      switch self {
      case .identifier(let columnIdentifier):
        return columnIdentifier.token
      case .default:
        return .default
      }
    }

    public static let plain: ModeName = .identifier("PLAIN")

    public static let external: ModeName = .identifier("EXTERNAL")

    public static let extended: ModeName = .identifier("EXTENDED")

    public static let main: ModeName = .identifier("MAIN")
  }

  public let name: ModeName

  @inlinable
  public var tokens: Array<Token> {
    return [.storage, name.token]
  }

  private init(name: ModeName) {
    self.name = name
  }

  /// `STORAGE PLAIN`
  public static let plain: ColumnStorageMode = .init(name: .plain)

  /// `STORAGE EXTERNAL`
  public static let external: ColumnStorageMode = .init(name: .external)

  /// `STORAGE EXTENDED`
  public static let extended: ColumnStorageMode = .init(name: .extended)

  /// `STORAGE MAIN`
  public static let main: ColumnStorageMode = .init(name: .main)

  /// `STORAGE DEFAULT`
  public static let `default`: ColumnStorageMode = .init(name: .default)
}
