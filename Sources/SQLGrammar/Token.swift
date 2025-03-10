/* *************************************************************************************************
 SQLToken.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import UnicodeSupplement

public typealias SQLIntegerType = FixedWidthInteger & UnsignedInteger
public typealias SQLFloatType   = BinaryFloatingPoint & CustomStringConvertible

private extension String {
  /// Used as a delimited identifier or a string constant.
  /// Adding "Unicode escapes" if its encoding is not `UTF-8` for safety.
  ///
  /// - Note: `NUL`s are removed.
  func _quoted(mark: Unicode.Scalar, isUTF8: Bool) -> String {
    assert(mark == "'" || mark == "\"")
    if isUTF8 {
      var resultScalars = UnicodeScalarView([mark])
      for scalar in self.unicodeScalars {
        if scalar.value == 0x00 {
          continue
        }
        if scalar == mark {
          resultScalars.append(contentsOf: [mark, mark])
        } else {
          resultScalars.append(scalar)
        }
      }
      resultScalars.append(mark)
      return String(resultScalars)
    } else {
      // non-UTF-8
      var resultScalars = UnicodeScalarView(["U", "&", mark])

      for scalar in self.unicodeScalars {
        let value = scalar.value

        if value == 0x00 {
          continue
        }

        func __appendEscapedScalars() {
          if value <= 0xFFFF {
            resultScalars.append(contentsOf: String(format: "\\%04X", value).unicodeScalars)
          } else {
            resultScalars.append(contentsOf: String(format: "\\+%06X", value).unicodeScalars)
          }
        }

        switch value {
        case 0x20..<0x7F where scalar != mark && scalar != "\\":
          resultScalars.append(scalar)
        default:
          __appendEscapedScalars()
        }
      }

      resultScalars.append(mark)
      return String(resultScalars)
    }
  }
}


/// A type representing SQL token.
@_ExpandStaticKeywords
public class Token: CustomStringConvertible, @unchecked Sendable {
  @usableFromInline
  internal let _rawValue: String

  private var __normalizedRawValue: String?
  private let _normalizedRawValueQueue: DispatchQueue = .init(
    label: "jp.YOCKOW.PQ.SQLGrammar.Token.normalizedRawValue",
    attributes: .concurrent
  )
  fileprivate var _normalizedRawValue: String {
    return _normalizedRawValueQueue.sync(flags: .barrier) {
      guard let normalizedRawValue = __normalizedRawValue else {
        let normalizedRawValue = _rawValue.lowercased()
        __normalizedRawValue = normalizedRawValue
        return normalizedRawValue
      }
      return normalizedRawValue
    }
  }

  fileprivate func isEqual(to other: Token) -> Bool {
    return self._normalizedRawValue == other._normalizedRawValue
  }

  @inlinable
  internal init(rawValue: String) {
    self._rawValue = rawValue
  }

  public var description: String {
    return _rawValue
  }

  /// A token that is able to be recognized as a keyword.
  public class Keyword: Token, @unchecked Sendable {
    /// A boolean value indicating whether or not it is an `unreserved_keyword`.
    public let isUnreserved: Bool

    /// A boolean value indicating whether or not it is an `col_name_keyword`.
    public let isAvailableForColumnName: Bool

    /// A boolean value indicating whether or not it is an `type_func_name_keyword`.
    public let isAvailableForTypeOrFunctionName: Bool

    /// A boolean value indicating whether or not it is an `reserved_keyword`.
    public let isReserved: Bool

    /// A boolean value indicating whether or not it is an `bare_label_keyword`.
    public let isBareLabel: Bool

    @inlinable
    internal init(
      rawValue: String,
      isUnreserved: Bool = false,
      isAvailableForColumnName: Bool = false,
      isAvailableForTypeOrFunctionName: Bool = false,
      isReserved: Bool = false,
      isBareLabel: Bool = false
    ) {
      self.isUnreserved = isUnreserved
      self.isAvailableForColumnName = isAvailableForColumnName
      self.isAvailableForTypeOrFunctionName = isAvailableForTypeOrFunctionName
      self.isReserved = isReserved
      self.isBareLabel = isBareLabel
      super.init(rawValue: rawValue)
    }
  }

  public class Identifier: Token, @unchecked Sendable {}

  public final class DelimitedIdentifier: Identifier, @unchecked Sendable {
    private let _isUTF8: Bool

    private var __description: String? = nil
    private let _descriptionQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.PQ.SQLGrammar.Token.DelimitedIdentifier.description",
      attributes: .concurrent
    )
    private var _description: String {
      return _descriptionQueue.sync(flags: .barrier) {
        guard let description = __description else {
          let description = _rawValue._quoted(mark: "\"", isUTF8: _isUTF8)
          __description = description
          return description
        }
        return description
      }
    }

    fileprivate override var _normalizedRawValue: String {
      return _description
    }

    public override var description: String {
      return _description
    }

    internal init(rawValue: String, encodingIsUTF8: Bool) {
      self._isUTF8 = encodingIsUTF8
      super.init(rawValue: rawValue)
    }
  }

  public final class StringConstant: Token, @unchecked Sendable {
    private let _isUTF8: Bool

    private var __description: String? = nil
    private let _descriptionQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.PQ.SQLGrammar.Token.StringConstant.description",
      attributes: .concurrent
    )
    private var _description: String {
      return _descriptionQueue.sync(flags: .barrier) {
        guard let description = __description else {
          let description = _rawValue._quoted(mark: "'", isUTF8: _isUTF8)
          __description = description
          return description
        }
        return description
      }
    }

    fileprivate override var _normalizedRawValue: String {
      return _description
    }

    public override var description: String {
      return _description
    }

    internal init(rawValue: String, encodingIsUTF8: Bool) {
      self._isUTF8 = encodingIsUTF8
      super.init(rawValue: rawValue)
    }
  }

  public class NumericConstant: Token, @unchecked Sendable {
    public let isInteger: Bool

    public let isFloat: Bool

    internal var isZero: Bool { fatalError("Must be overriden.") }

    internal var isOne: Bool { fatalError("Must be overriden.") }

    fileprivate init(isInteger: Bool, isFloat: Bool, rawValue: String) {
      self.isInteger = isInteger
      self.isFloat = isFloat
      super.init(rawValue: rawValue)
    }

    public final class Integer<U>: NumericConstant, @unchecked Sendable where U: SQLIntegerType {
      public let value: U

      internal override var isZero: Bool { value == 0 }

      internal override var isOne: Bool { value == 1 }

      internal init(_ value: U) {
        self.value = value
        super.init(isInteger: true, isFloat: false, rawValue: value.description)
      }
    }

    public final class Float<F>: NumericConstant, @unchecked Sendable where F: SQLFloatType {
      public let value: F

      internal override var isZero: Bool { value == 0.0 }

      internal override var isOne: Bool { value == 1.0 }

      internal init(_ value: F) {
        if value < 0 {
          fatalError("Negative value is not allowed here.")
        }
        self.value = value
        super.init(isInteger: false, isFloat: true, rawValue: value.description)
      }
    }
  }

  public final class BitStringConstant: Token, @unchecked Sendable {
    public enum Style {
      case binary
      case hexadecimal
    }

    public enum Error: Swift.Error {
      case invalidNotation
    }

    public let style: Style

    private var __description: String? = nil
    private let _descriptionQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.PQ.SQLGrammar.Token.StringConstant.description",
      attributes: .concurrent
    )
    private var _description: String {
      return _descriptionQueue.sync(flags: .barrier) {
        guard let description = __description else {
          let description = ({
            switch style {
            case .binary:
              return "B'\(_rawValue)'"
            case .hexadecimal:
              return "X'\(_rawValue.uppercased())'"
            }
          })()
          __description = description
          return description
        }
        return description
      }
    }

    fileprivate override var _normalizedRawValue: String {
      return _description
    }

    public override var description: String {
      return _description
    }

    public init(_ rawValue: String, style: Style) throws {
      switch style {
      case .binary:
        guard rawValue.unicodeScalars.allSatisfy({ $0 == "0" || $0 == "1" }) else {
          throw Error.invalidNotation
        }
      case .hexadecimal:
        guard rawValue.unicodeScalars.allSatisfy({
          switch $0 {
          case "0"..."9", "A"..."F", "a"..."f":
            return true
          default:
            return false
          }
        }) else {
          throw Error.invalidNotation
        }
      }
      self.style = style
      super.init(rawValue: rawValue)
    }
  }

  @_ExpandWellknownOperators
  public final class Operator: Token, @unchecked Sendable {
    public enum Error: Swift.Error {
      case empty
      case invalidCharacter
      case containsCommentStart
      case endInPlusOrMinus
    }

    public let isMathOperator: Bool

    private override init(rawValue: String) {
      self.isMathOperator = (
        rawValue == "+" ||
        rawValue == "-" ||
        rawValue == "*" ||
        rawValue == "/" ||
        rawValue == "%" ||
        rawValue == "^" ||
        rawValue == "<" ||
        rawValue == ">" ||
        rawValue == "=" ||
        rawValue == "<=" ||
        rawValue == ">=" ||
        rawValue == "<>"
      )
      super.init(rawValue: rawValue)
    }

    public convenience init(_ operatorName: String) throws {
      if operatorName.isEmpty {
        throw Error.empty
      }

      let scalars = operatorName.unicodeScalars
      var index = scalars.startIndex
      var canEndInPlusOrMinus = false
      var numberOfScalars = 0
      while true {
        let currentScalar = scalars[index]
        let nextIndex = scalars.index(after: index)
        let nextScalar: Unicode.Scalar? = nextIndex == scalars.endIndex ? nil : scalars[nextIndex]

        CHECK_SCALAR: switch currentScalar {
        case "~", "!", "@", "#", "%", "^", "&", "|", "`", "?":
          canEndInPlusOrMinus = true
        case "-":
          if let nextScalar, nextScalar == "-" {
            throw Error.containsCommentStart
          }
        case "/":
          if let nextScalar, nextScalar == "*" {
            throw Error.containsCommentStart
          }
        case "+", "*", "<", ">", "=":
          break CHECK_SCALAR
        default:
          throw Error.invalidCharacter
        }

        if nextIndex == scalars.endIndex {
          break
        }
        index = nextIndex
        numberOfScalars += 1
      }
      if numberOfScalars > 1 && !canEndInPlusOrMinus && (scalars.last == "+" || scalars.last == "-") {
        throw Error.endInPlusOrMinus
      }

      self.init(rawValue: operatorName)
    }

    /// Create a ':=' token.
    internal static let colonEquals: Operator = Operator(rawValue: ":=") // Skip validation.

    /// Create a '=>' token.
    internal static let arrowSign: Operator = Operator(rawValue: "=>")

    /// Creates a PostgreSQL-style type-cast operator ``::``.
    internal static let typeCast: Operator = Operator(rawValue: "::")
  }

  public class SpecialCharacter: Token, @unchecked Sendable {}

  /// A '$n' token described as `PARAM` in "gram.y".
  public final class PositionalParameter: SpecialCharacter, @unchecked Sendable {
    public init(_ position: UInt) {
      super.init(rawValue: "$\(position)")
    }
  }

  /// A token to remove whitespace.
  public final class Joiner: Token, @unchecked Sendable {
    fileprivate static let singleton: Joiner = .init(rawValue: "")
  }

  public final class Newline: Token, @unchecked Sendable {
    fileprivate static let singleton: Newline = .init(rawValue: "\n")
  }
}

/// Workaround for https://github.com/apple/swift/issues/70087
extension Token: Equatable {
  public static func ==(lhs: Token, rhs: Token) -> Bool {
    return lhs.isEqual(to: rhs)
  }
}

extension Token: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_normalizedRawValue)
  }
}

extension Token {
  /// Create an identifier token.
  /// "Unicode escapes" may be added when quoting is required and `encodingIsUTF8` is `false`.
  public static func identifier(_ string: String, forceQuoting: Bool = false, encodingIsUTF8: Bool = true) -> Token {
    var requireQuoting = forceQuoting

    if !requireQuoting && keyword(from: string) != nil {
      requireQuoting = true
    }

    CHECK_REQUIRE_QUOTING: if !requireQuoting {
      func __scalarIs(_ scalar: UnicodeScalar, _ property: KeyPath<Unicode.Scalar.LatestProperties, Bool>) -> Bool {
        if !encodingIsUTF8 {
          guard scalar.isASCII else { return false }
        }
        return scalar.latestProperties[keyPath: property]
      }

      let scalars = string.unicodeScalars
      guard let firstScalar = scalars.first, (firstScalar == "_" || __scalarIs(firstScalar, \.isLetter)) else {
        // Note: Zero-length delimeted identifier might be generated, but don't throw any errors here.
        requireQuoting = true
        break CHECK_REQUIRE_QUOTING
      }

      for scalar in scalars.dropFirst() {
        guard (
          scalar == "_" ||
          scalar == "$" ||
          ("0"..."9").contains(scalar) ||
          __scalarIs(scalar, \.isLetter) ||
          __scalarIs(scalar, \.isMark)
        ) else {
          requireQuoting = true
          break CHECK_REQUIRE_QUOTING
        }
      }
    }

    if !requireQuoting {
      return Identifier(rawValue: string)
    } else {
      return DelimitedIdentifier(rawValue: string, encodingIsUTF8: encodingIsUTF8)
    }
  }

  /// Create a string constant token.
  /// "Unicode escapes" are added when `encodingIsUTF8` is `false`.
  public static func string(_ string: String, encodingIsUTF8: Bool = true) -> Token {
    return StringConstant(rawValue: string, encodingIsUTF8: encodingIsUTF8)
  }

  /// Create a numeric constant token.
  public static func integer<T>(_ integer: T) -> Token where T: SQLIntegerType {
    return NumericConstant.Integer<T>(integer)
  }

  /// Create a numeric constant token.
  public static func integer(_ integer: UInt) -> Token {
    return NumericConstant.Integer<UInt>(integer)
  }

  /// Create a numeric constant token.
  public static func float<T>(_ float: T) -> Token where T: SQLFloatType {
    return NumericConstant.Float<T>(float)
  }

  public static func bitString(
    _ string: String,
    style: Token.BitStringConstant.Style
  ) throws -> Token {
    return try BitStringConstant(string, style: style)
  }

  /// Create an operator token.
  public static func `operator`(_ operatorName: String) throws -> Token {
    return try Operator(operatorName)
  }

  /// Create a positional parameter token.
  public static func positionalParameter(_ position: UInt) -> Token {
    return PositionalParameter(position)
  }

  /// Create a '(' token.
  public static let leftParenthesis: Token = SpecialCharacter(rawValue: "(")

  /// Create a ')' token.
  public static let rightParenthesis: Token = SpecialCharacter(rawValue: ")")

  /// Create a '[' token.
  public static let leftSquareBracket: Token = SpecialCharacter(rawValue: "[")

  /// Create a ']' token.
  public static let rightSquareBracket: Token = SpecialCharacter(rawValue: "]")

  /// Create a ',' token.
  public static let comma: Token = SpecialCharacter(rawValue: ",")

  /// Create a ';' token.
  public static let semicolon: Token = SpecialCharacter(rawValue: ";")

  /// Create a ':' token.
  public static let colon: Token = SpecialCharacter(rawValue: ":")

  /// Create a '*' token.
  public static let asterisk: Token = SpecialCharacter(rawValue: "*")

  /// Create a '.' token.
  public static let dot: Token = SpecialCharacter(rawValue: ".")

  /// Create a joiner token.
  public static let joiner: Token = Joiner.singleton

  /// Create a newline token.
  public static let newline: Token = Newline.singleton
}
