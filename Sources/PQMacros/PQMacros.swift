/* *************************************************************************************************
 PQMacros.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `binOp` macro, which takes an binary infix operator expression
/// and produces a constructor of `BinaryInfixOperatorInvocation`.
///
/// ## Examples
///
/// Macro                 | Expanded
/// ----------------------|-----------------------------------------------------------------------------------------------------------------------------------
/// `#binOp("a" + "'b'")` | `BinaryInfixOperatorInvocation(SingleToken.identifier("a"), Operator.single(SQLToken.Operator("+")), SingleToken.string("b"))`
/// `#binOp(1 + 2.3)`     | `BinaryInfixOperatorInvocation(SingleToken.integer(1), Operator.single(SQLToken.Operator("+")), SingleToken.float(2.3))`
/// `#binOp("c" < 4.5)`   | `BinaryInfixOperatorInvocation(SingleToken.identifier("c"), Operator.single(SQLToken.Operator("<")), SingleToken.float(4.5))`
///
public struct BinaryInfixOperatorInvocationMacro: ExpressionMacro {
  public enum MacroError: Error {
    case missingArgument
    case superfluousArguments
    case unsupportedExpression
    case unsupportedOperand
    case unsupportedOperator
  }

  public static func expansion(
    of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> SwiftSyntax.ExprSyntax {
    switch node.argumentList.count {
    case ..<1:
      throw MacroError.missingArgument
    case 2...:
      throw MacroError.superfluousArguments
    default:
      break
    }

    guard let infixOpExpr = node.argumentList.first!.expression.as(InfixOperatorExprSyntax.self) else {
      throw MacroError.unsupportedExpression
    }

    let left = infixOpExpr.leftOperand
    let op = infixOpExpr.operator
    let right = infixOpExpr.rightOperand

    func __modifyOperand(_ operand: ExprSyntax) throws -> ExprSyntax {
      if let stringLiteralExpr = operand.as(StringLiteralExprSyntax.self) {
        guard stringLiteralExpr.segments.count == 1,
              let stringSegment = stringLiteralExpr.segments.first!.as(StringSegmentSyntax.self)
        else {
          throw MacroError.unsupportedOperand
        }
        let textContent = stringSegment.content.text

        // Determine it should be an identifier or a string literal.
        if textContent.first == "'" && !textContent.dropFirst().isEmpty && textContent.last == "'" {
          // String literal
          let literal = StringLiteralExprSyntax(content: String(textContent.dropFirst().dropLast()))
          return "SingleToken.string(\(literal))"
        }
        return "SingleToken.identifier(\(stringLiteralExpr.trimmed))"
      }
      if let integerLiteralExpr = operand.as(IntegerLiteralExprSyntax.self) {
        return "SingleToken.integer(\(integerLiteralExpr.trimmed))"
      }
      if let floatLiteralExpr = operand.as(FloatLiteralExprSyntax.self) {
        return "SingleToken.float(\(floatLiteralExpr.trimmed))"
      }
      throw MacroError.unsupportedOperand
    }

    func __modifyOperator(_ operator: ExprSyntax) throws -> ExprSyntax {
      guard let binOp = `operator`.as(BinaryOperatorExprSyntax.self) else {
        throw MacroError.unsupportedOperator
      }
      return "Operator.single(SQLToken.Operator(\"\(raw: binOp.operator.text)\"))"
    }

    return try "BinaryInfixOperatorInvocation(\(__modifyOperand(left)), \(__modifyOperator(op)), \(__modifyOperand(right)))"
  }
}

@main
struct PQMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    BinaryInfixOperatorInvocationMacro.self,
  ]
}
