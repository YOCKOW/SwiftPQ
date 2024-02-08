/* *************************************************************************************************
 SQLToken.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import UnicodeSupplement

/// A type representing SQL token.
public class SQLToken: CustomStringConvertible, Equatable {
  private let _rawValue: String

  internal init(rawValue: String) {
    self._rawValue = rawValue
  }

  public var description: String {
    return _rawValue
  }

  public static func ==(lhs: SQLToken, rhs: SQLToken) -> Bool {
    guard Swift.type(of: lhs) == Swift.type(of: rhs) else { return false }
    return lhs._rawValue == rhs._rawValue
  }

  public class Keyword: SQLToken {}

  public class Identifier: SQLToken {}

  public class DelimitedIdentifier: SQLToken {
    private lazy var _description: String = ({
      var resultScalars: [Unicode.Scalar] = ["\""]
      for scalar in _rawValue.unicodeScalars {
        if scalar == "\"" {
          resultScalars.append(contentsOf: ["\"", "\""])
        } else {
          resultScalars.append(scalar)
        }
      }
      resultScalars.append("\"")
      return String(String.UnicodeScalarView(resultScalars))
    })()

    public override var description: String {
      return _description
    }
  }

  public class StringConstant: SQLToken {
    private lazy var _description: String = ({
      var resultScalars: [Unicode.Scalar] = ["'"]
      for scalar in _rawValue.unicodeScalars {
        if scalar == "'" {
          resultScalars.append(contentsOf: ["'", "'"])
        } else {
          resultScalars.append(scalar)
        }
      }
      resultScalars.append("'")
      return String(String.UnicodeScalarView(resultScalars))
    })()

    public override var description: String {
      return _description
    }
  }

  public class NumericConstant: SQLToken {
    public let isInteger: Bool
    public let isFloat: Bool
    public let isNegative: Bool

    fileprivate init<T>(_ integer: T) where T: FixedWidthInteger {
      self.isInteger = true
      self.isFloat = false
      self.isNegative = integer < 0
      super.init(rawValue: integer.description)
    }

    fileprivate init<T>(_ float: T) where T: BinaryFloatingPoint & CustomStringConvertible {
      self.isInteger = false
      self.isFloat = true
      self.isNegative = float < 0
      super.init(rawValue: float.description)
    }
  }

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

    fileprivate convenience init(operatorName: String) throws {
      if operatorName.isEmpty {
        throw Error.empty
      }

      let scalars = operatorName.unicodeScalars
      var index = scalars.startIndex
      var canEndInPlusOrMinus = false
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
      }
      if !canEndInPlusOrMinus && (scalars.last == "+" || scalars.last == "-") {
        throw Error.endInPlusOrMinus
      }

      self.init(rawValue: operatorName)
    }

    public static let lessThan: Operator = .init(rawValue: "<")

    public static let greaterThan: Operator = .init(rawValue: ">")

    public static let lessThanOrEqualTo: Operator = .init(rawValue: "<=")

    public static let greaterThanOrEqualTo: Operator = .init(rawValue: ">=")

    public static let equalTo: Operator = .init(rawValue: "=")

    public static let notEqualTo: Operator = .init(rawValue: "<>")

    public static let plus: Operator = .init(rawValue: "+")

    public static let minus: Operator = .init(rawValue: "-")

    public static let multiply: Operator = .init(rawValue: "*")

    public static let divide: Operator = .init(rawValue: "/")

    public static let modulo: Operator = .init(rawValue: "%")

    public static let exponent: Operator = .init(rawValue: "^")

    public static let squareRoot: Operator = .init(rawValue: "|/")

    public static let cubeRoot: Operator = .init(rawValue: "||/")

    public static let absoluteValue: Operator = .init(rawValue: "@")

    public static let bitwiseAnd: Operator = .init(rawValue: "&")

    public static let bitwiseOr: Operator = .init(rawValue: "|")

    public static let bitwiseExclusiveOr: Operator = .init(rawValue: "#")

    public static let bitwiseNot: Operator = .init(rawValue: "~")

    public static let bitwiseShiftLeft: Operator = .init(rawValue: "<<")

    public static let bitwiseShiftRight: Operator = .init(rawValue: ">>")
  }

  public class SpecialCharacter: SQLToken {}

  public class PositionalParameter: SpecialCharacter {}

  /// A token to remove whitespace.
  public final class Joiner: SQLToken {
    fileprivate static let singleton: Joiner = .init(rawValue: "")
  }
}

extension SQLToken {
  /// Create an identifier token.
  public static func identifier(_ string: String, forceQuoting: Bool = false) -> SQLToken {
    var requireQuoting = forceQuoting

    CHECK_REQUIRE_QUOTING: if !forceQuoting {
      let scalars = string.unicodeScalars
      guard let firstScalar = scalars.first, (
        firstScalar == "_" ||
        firstScalar.latestProperties.isLetter
      ) else {
        // Note: Zero-length delimeted identifier might be generated, but don't throw any errors here.
        requireQuoting = true
        break CHECK_REQUIRE_QUOTING
      }

      for scalar in scalars.dropFirst() {
        guard (
          scalar == "_" ||
          scalar == "$" ||
          ("0"..."9").contains(scalar) ||
          scalar.latestProperties.isLetter ||
          scalar.latestProperties.isMark
        ) else {
          requireQuoting = true
          break CHECK_REQUIRE_QUOTING
        }
      }
    }

    if !requireQuoting {
      return Identifier(rawValue: string)
    } else {
      return DelimitedIdentifier(rawValue: string)
    }
  }

  /// Create a string constant token.
  public static func string(_ string: String) -> SQLToken {
    return StringConstant(rawValue: string)
  }

  /// Create a numeric constant token.
  public static func numeric<T>(_ integer: T) -> SQLToken where T: FixedWidthInteger {
    return NumericConstant(integer)
  }

  /// Create a numeric constant token.
  public static func numeric<T>(_ float: T) -> SQLToken where T: BinaryFloatingPoint & CustomStringConvertible {
    return NumericConstant(float)
  }

  /// Create an operator token.
  public static func `operator`(_ operatorName: String) throws -> SQLToken {
    return try Operator(operatorName: operatorName)
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
