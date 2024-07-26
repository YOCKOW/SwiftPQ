/* *************************************************************************************************
 CommaSeparator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public struct SingleTokenIterator<T>: IteratorProtocol where T: Token {
  public let token: T
  private var _finished: Bool = false

  internal init(_ token: T) {
    self.token = token
  }

  public mutating func next() -> T? {
    if _finished {
      return nil
    }
    _finished = true
    return token
  }
}

/// A type that contains only one token, but conforms to `SQLTokenSequence`.
@_ExpandStaticKeywords
public struct SingleToken: TokenSequence {
  public let token: Token

  @inlinable
  internal init(_ token: Token) {
    self.token = token
  }

  @inlinable
  internal init<T>(_ object: T) where T: CustomTokenConvertible {
    self.init(object.token)
  }

  public typealias Tokens = Self
  public typealias Iterator = SingleTokenIterator<Token>

  public func makeIterator() -> Iterator {
    return .init(token)
  }

  public var isPositionalParameter: Bool {
    return token is Token.PositionalParameter
  }

  public var isIdentifier: Bool {
    return token is Token.Identifier || token is Token.DelimitedIdentifier
  }

  public var isInteger: Bool {
    return (token as? Token.NumericConstant)?.isInteger == true
  }

  public var isFloat: Bool {
    return (token as? Token.NumericConstant)?.isFloat == true
  }

  public static func positionalParameter(_ position: UInt) throws -> SingleToken {
    return .init(.positionalParameter(position))
  }

  public static func identifier(_ string: String, forceQuoting: Bool = false) -> SingleToken {
    return .init(.identifier(string, forceQuoting: forceQuoting))
  }

  public static func integer<T>(_ integer: T) -> SingleToken where T: SQLIntegerType {
    return .init(.integer(integer))
  }

  public static func float<T>(_ float: T) -> SingleToken where T: SQLFloatType {
    return .init(.float(float))
  }

  public static func string(_ string: String) -> SingleToken {
    return .init(.string(string))
  }

  public static let joiner: SingleToken = .init(.joiner)
}

internal extension Token {
  @inlinable
  var asSequence: some TokenSequence { return SingleToken(self) }
}
