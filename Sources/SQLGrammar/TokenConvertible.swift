/* *************************************************************************************************
 TokenConvertible.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type with a token representation.
public protocol CustomTokenConvertible {
  associatedtype CustomToken: Token = Token
  var token: CustomToken { get }
}

/// A type that can be represented as a token in a lossless, unambiguous way.
public protocol LosslessTokenConvertible: CustomTokenConvertible {
  init?(_ token: CustomToken)
}


internal extension CustomTokenConvertible {
  @inlinable
  var asSequence: some TokenSequence { self.token.asSequence }
}
