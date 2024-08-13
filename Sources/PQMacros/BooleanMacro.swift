/* *************************************************************************************************
 BooleanMacro.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct BooleanMacro: ExpressionMacro {
  public enum Error: Swift.Error {
    case unexpectedNumberOfArguments
    case notBoolean
    case unexpectedMacroName
  }

  public static let trueExprSyntax: ExprSyntax = "BooleanConstantExpression.true"

  public static let falseExprSyntax: ExprSyntax = "BooleanConstantExpression.false"

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
    
    switch node.macroName.text {
    case "bool", "boolean":
      guard arguments.count == 1 else { throw Error.unexpectedNumberOfArguments }
      guard let boolLiteral = arguments.first?.expression.as(BooleanLiteralExprSyntax.self) else {
        throw Error.notBoolean
      }
      if case .keyword(.true) = boolLiteral.literal.tokenKind {
        return trueExprSyntax
      } else if case .keyword(.false) = boolLiteral.literal.tokenKind {
        return falseExprSyntax
      }
      throw Error.notBoolean
    case "TRUE":
      guard arguments.isEmpty else { throw Error.unexpectedNumberOfArguments }
      return trueExprSyntax
    case "FALSE":
      guard arguments.isEmpty else { throw Error.unexpectedNumberOfArguments }
      return falseExprSyntax
    default:
      throw Error.unexpectedMacroName
    }
  }
}
