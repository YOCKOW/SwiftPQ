/* *************************************************************************************************
 UnknownSQLTokenSequence.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Unknown sequence of tokens.
internal final class UnknownSQLTokenSequence<Base>: TokenSequenceGenerator where Base: Sequence,
                                                                           Base.Element: Token {
  typealias Element = Base.Element
  typealias Tokens = Base

  let tokens: Base

  @inlinable
  init(_ base: Base) {
    self.tokens = base
  }

  @inlinable
  var underestimatedCount: Int {
    return tokens.underestimatedCount
  }

  @inlinable
  func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Base.Element>) throws -> R) rethrows -> R? {
    return try tokens.withContiguousStorageIfAvailable(body)
  }
}
