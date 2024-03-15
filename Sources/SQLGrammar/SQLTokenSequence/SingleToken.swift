/* *************************************************************************************************
 CommaSeparator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type that contains only one token, but conforms to `SQLTokenSequence`.
public struct SingleToken: SQLTokenSequence {
  public let token: SQLToken

  @inlinable
  internal init(_ token: SQLToken) {
    self.token = token
  }

  @inlinable
  internal init<T>(_ object: T) where T: CustomTokenConvertible {
    self.init(object.token)
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = SQLToken

    public let token: SQLToken
    private var _end: Bool = false
    internal init(_ token: SQLToken) {
      self.token = token
    }

    public mutating func next() -> Element? {
      guard !_end else { return nil }
      _end = true
      return token
    }
  }

  public func makeIterator() -> Iterator {
    return .init(token)
  }

  public var isPositionalParameter: Bool {
    return token is SQLToken.PositionalParameter
  }

  public var isIdentifier: Bool {
    return token is SQLToken.Identifier || token is SQLToken.DelimitedIdentifier
  }

  public var isInteger: Bool {
    return (token as? SQLToken.NumericConstant)?.isInteger == true
  }

  public var isFloat: Bool {
    return (token as? SQLToken.NumericConstant)?.isFloat == true
  }

  public var isNegativeNumeric: Bool {
    return (token as? SQLToken.NumericConstant)?.isNegative == true
  }

  public static func positionalParameter(_ position: UInt) throws -> SingleToken {
    return .init(try .positionalParameter(position))
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
}

internal extension SQLToken {
  var asSequence: some SQLTokenSequence { return SingleToken(self) }
}
