/* *************************************************************************************************
 DotJoiner.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Dot as a joiner.
public final class DotJoiner: TokenSequenceGenerator {
  public let tokens: [Token] = [.joiner, .dot, .joiner]
  public static let dotJoiner: DotJoiner = .init()
}

/// Dot joiner(.)
public let dotJoiner: DotJoiner = .dotJoiner
