/* *************************************************************************************************
 ConstantExpressionMacro.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConstantExpressionMacro: ExpressionMacro {
  public enum Error: Swift.Error {
     case unexpectedNumberOfArguments
     case unsupportedConstant
   }

  public static func expansion(
    of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> ExprSyntax {
    let arguments: LabeledExprListSyntax = ({
       #if compiler(>=5.10)
       return node.arguments
       #else
       return node.argumentList
       #endif
    })()

    guard arguments.count == 1 else { throw Error.unexpectedNumberOfArguments }

    let constantSwiftExpr = arguments.first!.expression

    if let stringExpr = constantSwiftExpr.as(StringLiteralExprSyntax.self) {
      return "StringConstantExpression(\(stringExpr))"
    } else if let intExpr = constantSwiftExpr.as(IntegerLiteralExprSyntax.self) {
      return "UnsignedIntegerConstantExpression(\(intExpr))"
    }

    throw Error.unsupportedConstant
  }
}
