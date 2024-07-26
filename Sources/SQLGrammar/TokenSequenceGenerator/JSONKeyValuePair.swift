/* *************************************************************************************************
 JSONKeyValuePair.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A JSON name-value pair, described as `json_name_and_value` in "gram.y".
public struct JSONKeyValuePair: TokenSequenceGenerator {
  public enum Delimiter: LosslessTokenConvertible {
    case valueKeyword
    case colon

    public var token: Token {
      switch self {
      case .valueKeyword:
        return .value
      case .colon:
        return .colon
      }
    }

    public init?(_ token: Token) {
      switch token {
      case .value:
        self = .valueKeyword
      case .colon:
        self = .colon
      default:
        return nil
      }
    }
  }

  public let key: any GeneralExpression

  public let delimiter: Delimiter

  public let value: JSONValueExpression

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence([
      key,
      SingleToken(delimiter),
      value
    ] as [any TokenSequenceGenerator])
  }

  public init(key: any GeneralExpression, value: JSONValueExpression) {
    self.key = key
    self.delimiter = .colon
    self.value = value
  }

  public init<Expr>(
    key: Expr,
    delimiter: Delimiter = .valueKeyword,
    value: JSONValueExpression
  ) where Expr: ProductionExpression {
    self.key = key
    self.delimiter = delimiter
    self.value = value
  }
}
