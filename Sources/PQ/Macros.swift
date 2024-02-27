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
/// `#binOp("a" + "'b'")` | `BinaryInfixOperatorInvocation(SingleToken.identifier("a"), Operator.single(SQLToken.Operator("+")), SingleToken.string("b"))`
/// `#binOp(1 + 2.3)`     | `BinaryInfixOperatorInvocation(SingleToken.integer(1), Operator.single(SQLToken.Operator("+")), SingleToken.float(2.3))`
/// `#binOp("c" < 4.5)`   | `BinaryInfixOperatorInvocation(SingleToken.identifier("c"), Operator.single(SQLToken.Operator("<")), SingleToken.float(4.5))`
///
@freestanding(expression)
public macro binOp(_ value: _BinaryInfixOperatorInvocationMacroResult) -> BinaryInfixOperatorInvocation = #externalMacro(module: "PQMacros", type: "BinaryInfixOperatorInvocationMacro")

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "PQMacros", type: "StringifyMacro")

