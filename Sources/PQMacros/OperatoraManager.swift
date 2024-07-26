/* *************************************************************************************************
 OperatorManager.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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

  var allOperatorNames: [String] {
    return Array<String>(binaryOperatorNames) + unaryPrefixOperatorNames
  }

  func `operator`(for name: String) -> String? {
    return _nameToBinOp[name] ?? _nameToUnaryPrefixOp[name]
  }

  func name(of operator: String) -> String? {
    return _binOpToName[`operator`] ?? _unaryPrefixOpToName[`operator`]
  }
}

/// Expand static members of `Operator` and `SQLToken.Operator`
///
/// - Note: Only for the purpose of internal use.
public struct WellknownOperatorsExpander: MemberMacro {
  public enum Error: Swift.Error {
    case unsupportedType
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let tokenClassDecl = declaration.as(ClassDeclSyntax.self),
          tokenClassDecl.name.text == "Operator",
          (tokenClassDecl.inheritanceClause?.inheritedTypes.contains(where: {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text == "Token"
          }) == true)
    else {
      throw Error.unsupportedType
    }

    let opMap = OperatorMap.map
    let generateDecl: (String) -> DeclSyntax = {
      let op = opMap.operator(for: $0)!
      return """
      /// An operator token `\(raw: op)`
      public static let \(raw: $0): Token.Operator = .init(rawValue: \"\(raw: op)\")
      """
    }
    return opMap.allOperatorNames.sorted().map(generateDecl)
  }
}
