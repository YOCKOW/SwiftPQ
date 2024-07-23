/* *************************************************************************************************
 BinaryInfixOperatorInvocationMacro.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private func _operatorConstuctorExpr(for operator: String, dotSyntax: Bool = false) -> ExprSyntax {
  if let name = OperatorMap.map.name(of: `operator`) {
    return dotSyntax ? ".\(raw: name)" : "Operator.\(raw: name)"
  }
  let operatorStringLiteral = StringLiteralExprSyntax(content: `operator`)
  return dotSyntax ? ".single(.init(\(operatorStringLiteral)))" : "Operator.single(SQLToken.Operator(\(operatorStringLiteral)))"
}

/// Implementation of the `binOp` macro, which takes an binary infix operator expression
/// and produces a constructor of `BinaryInfixOperatorInvocation`.
///
/// ## Examples
///
/// Macro                 | Expanded
/// ----------------------|-----------------------------------------------------------------------------------------------------------------------------------
/// `#binOp("a" + "'b'")` | `BinaryInfixOperatorInvocation(SingleToken.identifier("a"), .plus, SingleToken.string("b"))`
/// `#binOp(1 + 2.3)`     | `BinaryInfixOperatorInvocation(SingleToken.integer(1), .plus, SingleToken.float(2.3))`
/// `#binOp("c" < 4.5)`   | `BinaryInfixOperatorInvocation(SingleToken.identifier("c"), .lessThan, SingleToken.float(4.5))`
/// `#binOp("n", "=", 2)` | `BinaryInfixOperatorInvocation(SingleToken.identifier("n"), .equalTo, SingleToken.integer(2))`
///
public struct BinaryInfixOperatorInvocationMacro: ExpressionMacro {
  public enum Error: Swift.Error {
    case unexpectedNumberOfArguments
    case unsupportedExpression
    case unsupportedOperand
    case unsupportedOperator
  }

  public static func expansion(
    of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> SwiftSyntax.ExprSyntax {
    let arguments: LabeledExprListSyntax = ({
      #if compiler(>=5.10)
      return node.arguments
      #else
      return node.argumentList
      #endif
    })()

    let (left, op, right): (ExprSyntax, ExprSyntax, ExprSyntax) = try ({
      switch arguments.count {
      case 1:
        guard let infixOpExpr = arguments.first!.expression.as(InfixOperatorExprSyntax.self) else {
          throw Error.unsupportedExpression
        }
        return (infixOpExpr.leftOperand, infixOpExpr.operator, infixOpExpr.rightOperand)
      case 3:
        return (
          arguments.first!.expression,
          arguments[arguments.index(after: arguments.startIndex)].expression,
          arguments.last!.expression
        )
      default:
        throw Error.unexpectedNumberOfArguments
      }
    })()

    func __modifyOperand(_ operand: ExprSyntax) throws -> ExprSyntax {
      if let stringLiteralExpr = operand.as(StringLiteralExprSyntax.self) {
        guard stringLiteralExpr.segments.count == 1,
              let stringSegment = stringLiteralExpr.segments.first!.as(StringSegmentSyntax.self)
        else {
          throw Error.unsupportedOperand
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
      throw Error.unsupportedOperand
    }

    func __modifyOperator(_ operator: ExprSyntax) throws -> ExprSyntax {
      if let binOp = `operator`.as(BinaryOperatorExprSyntax.self) {
        return _operatorConstuctorExpr(for: binOp.operator.text, dotSyntax: true)
      }
      if let binOpDescLiteral = `operator`.as(StringLiteralExprSyntax.self),
         binOpDescLiteral.segments.count == 1,
         let binOpDescSegment = binOpDescLiteral.segments.first?.as(StringSegmentSyntax.self) {
        return _operatorConstuctorExpr(for: binOpDescSegment.content.text, dotSyntax: true)
      }
      throw Error.unsupportedOperator
    }

    return try "BinaryInfixOperatorInvocation(\(__modifyOperand(left)), \(__modifyOperator(op)), \(__modifyOperand(right)))"
  }
}

public struct BinaryInfixOperatorInvocationShortcutMacro: MemberMacro {
  public enum Error: Swift.Error {
    case notExtensionDecl
    case unsupportedType
  }

  private enum _ExtendedType {
    case tokenSequence
    case token
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let extDecl = declaration.as(ExtensionDeclSyntax.self) else {
      throw Error.notExtensionDecl
    }

    let extendedType: _ExtendedType = try ({
      switch extDecl.extendedType.as(IdentifierTypeSyntax.self)?.name.text {
      case "SQLTokenSequence":
        return .tokenSequence
      case "SQLToken":
        return .token
      default:
        throw Error.unsupportedType
      }
    })()

    let map = OperatorMap.map

    let generateDecls: (String) -> [DeclSyntax] = switch extendedType {
    case .tokenSequence:
      { (name: String) -> [DeclSyntax] in
        let op = map.operator(for: name)!
        return [
          """
          /// Create an invocation that is a sequence of tokens as `self \(raw: op) right`.
          public func \(raw: name)(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
            return .init(self, .\(raw: name), rhs)
          }
          """,
          """
          /// Create an invocation that is a sequence of tokens as `self \(raw: op) right`.
          public func \(raw: name)(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
            return \(raw: name)(rhs.asSequence)
          }
          """
        ]
      }
    case .token:
      { (name: String) -> [DeclSyntax] in
        let op = map.operator(for: name)!
        return [
          """
          /// Create an invocation that is a sequence of tokens as `self \(raw: op) right`.
          public func \(raw: name)(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
            return self.asSequence.\(raw: name)(rhs)
          }
          """,
          """
          /// Create an invocation that is a sequence of tokens as `self \(raw: op) right`.
          public func \(raw: name)(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
            return \(raw: name)(rhs.asSequence)
          }
          """
        ]
      }
    }

    return map.binaryOperatorNames.sorted().flatMap(generateDecls)
  }
}
