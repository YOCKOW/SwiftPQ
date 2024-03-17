/* *************************************************************************************************
 SQLToken.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import UnicodeSupplement

public typealias SQLIntegerType = FixedWidthInteger
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

// TODO: Drop 'SQL' prefix!

/// A type representing SQL token.
@_ExpandStaticKeywords
public class SQLToken: CustomStringConvertible {
  @usableFromInline
  internal let _rawValue: String

  @inlinable
  internal init(rawValue: String) {
    self._rawValue = rawValue
  }

  public var description: String {
    return _rawValue
  }

  /// A token that is able to be recognized as a keyword.
  public class Keyword: SQLToken {
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

  public class Identifier: SQLToken {}

  public class DelimitedIdentifier: Identifier {
    private let _isUTF8: Bool

    private lazy var _description: String = _rawValue._quoted(mark: "\"", isUTF8: _isUTF8)

    public override var description: String {
      return _description
    }

    internal init(rawValue: String, encodingIsUTF8: Bool) {
      self._isUTF8 = encodingIsUTF8
      super.init(rawValue: rawValue)
    }
  }

  public class StringConstant: SQLToken {
    private let _isUTF8: Bool

    private lazy var _description: String = _rawValue._quoted(mark: "'", isUTF8: _isUTF8)

    public override var description: String {
      return _description
    }

    internal init(rawValue: String, encodingIsUTF8: Bool) {
      self._isUTF8 = encodingIsUTF8
      super.init(rawValue: rawValue)
    }
  }

  public class NumericConstant: SQLToken {
    public let isInteger: Bool
    public let isFloat: Bool
    public let isNegative: Bool

    internal init<T>(_ integer: T) where T: SQLIntegerType {
      self.isInteger = true
      self.isFloat = false
      self.isNegative = integer < 0
      super.init(rawValue: integer.description)
    }

    internal init<T>(_ float: T) where T: SQLFloatType {
      self.isInteger = false
      self.isFloat = true
      self.isNegative = float < 0
      super.init(rawValue: float.description)
    }
  }

  @_WellknownOperators
  public class Operator: SQLToken {
    public enum Error: Swift.Error {
      case empty
      case invalidCharacter
      case containsCommentStart
      case endInPlusOrMinus
    }

    private override init(rawValue: String) {
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
  }

  public class SpecialCharacter: SQLToken {}

  public class PositionalParameter: SpecialCharacter {}

  /// A token to remove whitespace.
  public final class Joiner: SQLToken {
    fileprivate static let singleton: Joiner = .init(rawValue: "")
  }
}

/// Workaround for https://github.com/apple/swift/issues/70087
extension SQLToken: Equatable {
  public static func ==(lhs: SQLToken, rhs: SQLToken) -> Bool {
    guard Swift.type(of: lhs) == Swift.type(of: rhs) else { return false }
    return lhs._rawValue == rhs._rawValue
  }
}

extension SQLToken {
  /// Create an identifier token.
  /// "Unicode escapes" may be added when quoting is required and `encodingIsUTF8` is `false`.
  public static func identifier(_ string: String, forceQuoting: Bool = false, encodingIsUTF8: Bool = true) -> SQLToken {
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
  public static func string(_ string: String, encodingIsUTF8: Bool = true) -> SQLToken {
    return StringConstant(rawValue: string, encodingIsUTF8: encodingIsUTF8)
  }

  /// Create a numeric constant token.
  public static func integer<T>(_ integer: T) -> SQLToken where T: SQLIntegerType {
    return NumericConstant(integer)
  }

  /// Create a numeric constant token.
  public static func float<T>(_ float: T) -> SQLToken where T: SQLFloatType {
    return NumericConstant(float)
  }

  /// Create an operator token.
  public static func `operator`(_ operatorName: String) throws -> SQLToken {
    return try Operator(operatorName)
  }

  /// Create a positional parameter token.
  public static func positionalParameter(_ position: UInt) throws -> SQLToken {
    return PositionalParameter(rawValue: "$\(position)")
  }

  /// Create a '(' token.
  public static let leftParenthesis: SQLToken = SpecialCharacter(rawValue: "(")

  /// Create a ')' token.
  public static let rightParenthesis: SQLToken = SpecialCharacter(rawValue: ")")

  /// Create a '[' token.
  public static let leftSquareBracket: SQLToken = SpecialCharacter(rawValue: "[")

  /// Create a ']' token.
  public static let rightSquareBracket: SQLToken = SpecialCharacter(rawValue: "]")

  /// Create a ',' token.
  public static let comma: SQLToken = SpecialCharacter(rawValue: ",")

  /// Create a ';' token.
  public static let semicolon: SQLToken = SpecialCharacter(rawValue: ";")

  /// Create a ':' token.
  public static let colon: SQLToken = SpecialCharacter(rawValue: ":")

  /// Create a '*' token.
  public static let asterisk: SQLToken = SpecialCharacter(rawValue: "*")

  /// Create a '.' token.
  public static let dot: SQLToken = SpecialCharacter(rawValue: ".")

  /// Create a joiner token.
  public static let joiner: SQLToken = Joiner.singleton
}

