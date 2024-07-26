/* *************************************************************************************************
 NoInherit.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of `opt_no_inherit` in "gram.y".
public final class NoInherit: Segment {
  public let tokens: Array<Token> = [.no, .inherit]
  private init() {}
  public static let noInherit: NoInherit = .init()
}
