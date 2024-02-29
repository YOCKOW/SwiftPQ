/* *************************************************************************************************
 OperatorManager.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Map of well-known operators.
internal final class OperatorMap {
  private init() {}

  static let map: OperatorMap = .init()

  private let _nameToBinOp: [String: String] = [
    "lessThan": "<",
    "greaterThan": ">",
    "lessThanOrEqualTo": "<=",
    "greaterThanOrEqualTo": ">=",
    "equalTo": "=",
    "notEqualTo": "<>",
    "plus": "+",
    "minus": "-",
    "multiply": "*",
    "divide": "/",
    "modulo": "%",
    "exponent": "^",
    "bitwiseAnd": "&",
    "bitwiseOr": "|",
    "bitwiseExclusiveOr": "#",
    "bitwiseShiftLeft": "<<",
    "bitwiseShiftRight": ">>",
  ]

  private let _nameToUnaryPrefixOp: [String: String] = [
    "squareRoot": "|/",
    "cubeRoot": "||/",
    "factorial": "!!",
    "absoluteValue": "@",
    "bitwiseNot": "~",
  ]

  private lazy var _binOpToName: [String: String] = _nameToBinOp.reduce(into: [:]) { $0[$1.value] = $1.key }

  private lazy var _unaryPrefixOpToName: [String: String] = _nameToUnaryPrefixOp.reduce(into: [:]) { $0[$1.value] = $1.key }

  var binaryOperatorNames: Dictionary<String, String>.Keys {
    return _nameToBinOp.keys
  }

  var unaryPrefixOperatorNames: Dictionary<String, String>.Keys {
    return _nameToUnaryPrefixOp.keys
  }

  func `operator`(for name: String) -> String? {
    return _nameToBinOp[name] ?? _nameToUnaryPrefixOp[name]
  }

  func name(of operator: String) -> String? {
    return _binOpToName[`operator`] ?? _unaryPrefixOpToName[`operator`]
  }
}
