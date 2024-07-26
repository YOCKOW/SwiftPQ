/* *************************************************************************************************
 ColumnCompressionMode.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// The compression method for the column that is described as `column_compression` in "gram.y".
public struct ColumnCompressionMode: TokenSequenceGenerator {
  public enum ModeName: CustomTokenConvertible, ExpressibleByStringLiteral {
    case identifier(ColumnIdentifier)
    case `default`

    @inlinable
    public var token: SQLToken {
      switch self {
      case .identifier(let columnIdentifier):
        return columnIdentifier.token
      case .default:
        return .default
      }
    }

    public init(stringLiteral value: String) {
      if value.lowercased() == "default" {
        self = .default
      } else {
        self = .identifier(ColumnIdentifier(stringLiteral: value))
      }
    }

    public static let pglz: ModeName = .identifier("pglz")

    public static let lz4: ModeName = .identifier("lz4")
  }

  public let name: ModeName

  @inlinable
  public var tokens: Array<SQLToken> {
    return [.compression, name.token]
  }

  public init(name: ModeName) {
    self.name = name
  }

  public static let pglz: ColumnCompressionMode = .init(name: .pglz)

  public static let lz4: ColumnCompressionMode = .init(name: .lz4)
}
