/* *************************************************************************************************
 TokenSequenceGenerator+Array.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

extension Array {
  /// Creates a new array from `sequence`.
  @inlinable
  public init<T>(_ generator: T) where T: TokenSequenceGenerator, T.Tokens == Array<Element> {
    self = generator.tokens
  }
}

extension Array where Element == Token {
  /// Creates a new array from `sequence`.
  @inlinable
  public init<S>(_ sequence: S) where S: Sequence, S.Element: Token {
    switch sequence {
    case let array as Array<Token>:
      self = array
    default:
      self = sequence.map({ $0 as Token })
    }
  }
}
