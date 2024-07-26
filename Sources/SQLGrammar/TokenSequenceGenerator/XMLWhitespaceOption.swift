/* *************************************************************************************************
 XMLWhitespaceOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to determine how to parse XML whitespaces.
/// It is described as `xml_whitespace_option` in "gram.y".
public enum XMLWhitespaceOption: TokenSequenceGenerator {
  case preserve
  case strip

  private static let _preserveTokens: [Token] = [.preserve, .whitespace]
  private static let _stripTokens: [Token] = [.strip, .whitespace]

  public var tokens: Array<Token> {
    switch self {
    case .preserve:
      return XMLWhitespaceOption._preserveTokens
    case .strip:
      return XMLWhitespaceOption._stripTokens
    }
  }
}
