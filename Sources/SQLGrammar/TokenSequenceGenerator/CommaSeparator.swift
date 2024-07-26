/* *************************************************************************************************
 CommaSeparator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Comma as a separator.
public final class CommaSeparator: TokenSequenceGenerator {
  public let tokens: [Token] = [.joiner, .comma]
  public static let commaSeparator: CommaSeparator = .init()
}

/// Comma separator (,)
public let commaSeparator: CommaSeparator = .commaSeparator
