/* *************************************************************************************************
 SQLTokenSequence+Array.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

extension Array {
  /// Creates a new array from `sequence`.
  @inlinable
  public init<T>(_ sequence: T) where T: SQLTokenSequence, T.Tokens == Array<Element> {
    self = sequence.tokens
  }
}

extension Array where Element == SQLToken {
  /// Creates a new array from `sequence`.
  @inlinable
  public init<S>(_ sequence: S) where S: Sequence, S.Element: SQLToken {
    switch sequence {
    case let array as Array<SQLToken>:
      self = array
    default:
      self = sequence.map({ $0 as SQLToken })
    }
  }
}
