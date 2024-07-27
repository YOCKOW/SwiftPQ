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
    case unsupportedPrefixOperator
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

    func __numericConstructorExpr(from swiftExpr: some ExprSyntaxProtocol) throws -> ExprSyntax {
      if let intExpr = swiftExpr.as(IntegerLiteralExprSyntax.self) {
        return "UnsignedIntegerConstantExpression(\(intExpr))"
      }
      if let floatExpr = swiftExpr.as(FloatLiteralExprSyntax.self) {
        return "UnsignedFloatConstantExpression(\(floatExpr))"
      }
      throw Error.unsupportedConstant
    }

    let constantSwiftExpr = arguments.first!.expression

    if let stringExpr = constantSwiftExpr.as(StringLiteralExprSyntax.self) {
      return "StringConstantExpression(\(stringExpr))"
    }
    
    if let numericConstructorExpr = try? __numericConstructorExpr(from: constantSwiftExpr) {
      return numericConstructorExpr
    }

    if let prefixOpExpr = constantSwiftExpr.as(PrefixOperatorExprSyntax.self) {
      let prefixOpTypeName: DeclReferenceExprSyntax = try ({
        switch prefixOpExpr.operator.text {
        case "+":
          return .init(baseName: "UnaryPrefixPlusOperatorInvocation")
        case "-":
          return .init(baseName: "UnaryPrefixMinusOperatorInvocation")
        default:
          throw Error.unsupportedPrefixOperator
        }
      })()
      let operandExpr = try __numericConstructorExpr(from: prefixOpExpr.expression)
      return "\(prefixOpTypeName)(\(operandExpr))"
    }

    throw Error.unsupportedConstant
  }
}
