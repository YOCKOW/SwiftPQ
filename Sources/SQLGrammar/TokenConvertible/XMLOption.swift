/* *************************************************************************************************
 XMLOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to determine how to parse/serialize XML.
/// It is described as `document_or_content` in "gram.y"
public enum XMLOption: LosslessTokenConvertible {
  case document
  case content

  public var token: Token {
    switch self {
    case .document:
      return .document
    case .content:
      return .content
    }
  }

  public init?(_ token: Token) {
    switch token {
    case .document:
      self = .document
    case .content:
      self = .content
    default:
      return nil
    }
  }
}

