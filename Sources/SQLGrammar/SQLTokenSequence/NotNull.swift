/* *************************************************************************************************
 NotNull.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

internal final class NotNull: Segment {
  let tokens: Array<SQLToken> = [.not, .null]
  private init() {}
  static let notNull: NotNull = .init()
}
