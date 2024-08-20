/* *************************************************************************************************
 ConstantTypeCastStringLiteralSyntaxMacro.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConstantTypeCastStringLiteralSyntaxMacro: ExpressionMacro {
  public enum Error: Swift.Error {
    case unexpectedNumberOfArguments
    case unexpectedMacroName
  }

  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    let arguments = node.arguments
    guard arguments.count == 1 else {
      throw Error.unexpectedNumberOfArguments
    }

    switch node.macroName.text {
    case "TIMESTAMP":
      let stringExpr = arguments.first!
      return """
      ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
        constantTypeName: .timestamp,
        string: \(stringExpr)
      )
      """
    case "TIMESTAMPTZ", "TIMESTAMP_WITH_TIME_ZONE":
      let stringExpr = arguments.first!
      return """
      ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
        constantTypeName: .timestamp(withTimeZone: true),
        string: \(stringExpr)
      )
      """
    default:
      throw Error.unexpectedMacroName
    }
  }
}
