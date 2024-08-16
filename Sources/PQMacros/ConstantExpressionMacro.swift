/* *************************************************************************************************
 ConstantExpressionMacro.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that produces a constructor of some kind of `Expression`.
///
/// Macro              | Expanded
/// -------------------|----------------------------------------------------------------------------
/// `#const("string")` | `StringConstantExpression("string")`
/// `#const(123)`      | `UnsignedIntegerConstantExpression(123)`
/// `#const(123.45)`   | `UnsignedFloatConstantExpression(123.45)`
/// `#const(+123)`     | `UnaryPrefixPlusOperatorInvocation(UnsignedIntegerConstantExpression(123))`
/// `#const(+123.45)`  | `UnaryPrefixPlusOperatorInvocation(UnsignedFloatConstantExpression(123.45))`
/// `#const(-123)`     | `UnaryPrefixMinusOperatorInvocation(UnsignedIntegerConstantExpression(123))`
/// `#const(-123.45)`  | `UnaryPrefixMinusOperatorInvocation(UnsignedFloatConstantExpression(123.45))`
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

    func __convertible(_ expr: ExprSyntax) -> Bool {
      return (
        expr.is(StringLiteralExprSyntax.self)
        || expr.is(IntegerLiteralExprSyntax.self)
        || expr.is(FloatLiteralExprSyntax.self)
        || expr.is(PrefixOperatorExprSyntax.self)
        || expr.is(BooleanLiteralExprSyntax.self)
      )
    }

    func __convert(_ constantExpr: ExprSyntax) throws -> ExprSyntax {
      func __numericConstructorExpr(from swiftExpr: some ExprSyntaxProtocol) throws -> ExprSyntax {
        if let intExpr = swiftExpr.as(IntegerLiteralExprSyntax.self) {
          return "UnsignedIntegerConstantExpression(\(intExpr))"
        }
        if let floatExpr = swiftExpr.as(FloatLiteralExprSyntax.self) {
          return "UnsignedFloatConstantExpression(\(floatExpr))"
        }
        throw Error.unsupportedConstant
      }

      func __signedNumericConstructorExpr(
        from prefixOpExpr: PrefixOperatorExprSyntax
      ) throws -> ExprSyntax {
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

      if let stringExpr = constantExpr.as(StringLiteralExprSyntax.self) {
        return "StringConstantExpression(\(stringExpr))"
      }

      if let numericConstructorExpr = try? __numericConstructorExpr(from: constantExpr) {
        return numericConstructorExpr
      }

      if let prefixOpExpr = constantExpr.as(PrefixOperatorExprSyntax.self) {
        return try __signedNumericConstructorExpr(from: prefixOpExpr)
      }

      if let boolExpr = constantExpr.as(BooleanLiteralExprSyntax.self) {
        switch boolExpr.literal.tokenKind {
        case .keyword(.true):
          return BooleanMacro.trueExprSyntax
        case .keyword(.false):
          return BooleanMacro.falseExprSyntax
        default:
          throw Error.unsupportedConstant
        }
      }

      throw Error.unsupportedConstant
    }

    let constantSwiftExpr = arguments.first!.expression

    if __convertible(constantSwiftExpr) {
      return try __convert(constantSwiftExpr)
    }

    if let asExpr = constantSwiftExpr.as(AsExprSyntax.self) {
      return try __convert(asExpr.expression)
    }

    if let funcCallExpr = constantSwiftExpr.as(FunctionCallExprSyntax.self),
       funcCallExpr.arguments.count == 1,
       let firstExpr = funcCallExpr.arguments.first?.expression,
       __convertible(firstExpr) {
      return try __convert(firstExpr)
    }

    throw Error.unsupportedConstant
  }
}
