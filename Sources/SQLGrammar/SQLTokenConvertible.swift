/* *************************************************************************************************
 SQLTokenConvertible.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type with a token representation.
public protocol CustomTokenConvertible {
  associatedtype Token: SQLToken = SQLToken
  var token: Token { get }
}

/// A type that can be represented as a token in a lossless, unambiguous way.
public protocol LosslessTokenConvertible: CustomTokenConvertible {
  init?(_ token: Token)
}
