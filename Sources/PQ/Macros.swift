/* *************************************************************************************************
 Macros.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// This type is intended to be used only as a return type in #binOp macro.
public struct _BinaryInfixOperatorInvocationMacroResult {
  public static let result: _BinaryInfixOperatorInvocationMacroResult = .init()
}
infix operator <> : ComparisonPrecedence

/// This type is intended to be used only as an operand in #binOp macro.
public struct _BinaryInfixOperatorInvocationMacroOperand: ExpressibleByStringLiteral,
                                                          ExpressibleByIntegerLiteral,
                                                          ExpressibleByFloatLiteral {
  public typealias StringLiteralType = String
  public typealias IntegerLiteralType = Int
  public typealias FloatLiteralType = Double
  public init(stringLiteral value: String) {}
  public init(integerLiteral value: Int) {}
  public init(floatLiteral value: Double) {}

  public static func <(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func >(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func <=(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func >=(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func <>(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func +(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func -(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func *(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func /(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func %(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func ^(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func <<(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
  public static func >>(_ lhs: Self, _ rhs: Self) -> _BinaryInfixOperatorInvocationMacroResult { .result }
}

/// A macro that produces a constructor of `BinaryInfixOperatorInvocation`.
///
///
/// ## Examples
///
/// Macro                 | Expanded
/// ----------------------|-----------------------------------------------------------------------------------------------------------------------------------
/// `#binOp("a" + "'b'")` | `BinaryInfixOperatorInvocation(SingleToken.identifier("a"), .plus, SingleToken.string("b"))`
/// `#binOp(1 + 2.3)`     | `BinaryInfixOperatorInvocation(SingleToken.integer(1), .plus, SingleToken.float(2.3))`
/// `#binOp("c" < 4.5)`   | `BinaryInfixOperatorInvocation(SingleToken.identifier("c"), .lessThan, SingleToken.float(4.5))`
///
@freestanding(expression)
public macro binOp(_ value: _BinaryInfixOperatorInvocationMacroResult) -> BinaryInfixOperatorInvocation = #externalMacro(module: "PQMacros", type: "BinaryInfixOperatorInvocationMacro")


@attached(member, names: arbitrary)
internal macro _WellknownOperators() = #externalMacro(module: "PQMacros", type: "WellknownOperatorsMacro")

@attached(member, names: arbitrary)
internal macro _BinaryInfixOperatorInvocationShortcut() =  #externalMacro(module: "PQMacros", type: "BinaryInfixOperatorInvocationShortcutMacro")
