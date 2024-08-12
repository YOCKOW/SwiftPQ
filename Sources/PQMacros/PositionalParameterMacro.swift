/* *************************************************************************************************
 PositionalParameterMacro.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PositionalParameterMacro: ExpressionMacro {
  public enum Error: Swift.Error {
    case unexpectedNumberOfArguments
    case notInteger
    case invalidInteger
    case unexpectedMacroName
  }

  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let arguments: LabeledExprListSyntax = ({
       #if compiler(>=5.10)
       return node.arguments
       #else
       return node.argumentList
       #endif
    })()
    
    guard arguments.count == 1 else { throw Error.unexpectedNumberOfArguments }

    guard let intLiteral = arguments.first?.expression.as(IntegerLiteralExprSyntax.self) else {
      throw Error.notInteger
    }
    guard let pos = UInt(intLiteral.literal.text) else {
      throw Error.invalidInteger
    }

    switch node.macroName.text {
    case "param":
      return "Token.PositionalParameter(\(raw: pos))"
    case "paramExpr":
      return "Token.PositionalParameter(\(raw: pos)).asExpression"
    default:
      throw Error.unexpectedMacroName
    }
  }
}
