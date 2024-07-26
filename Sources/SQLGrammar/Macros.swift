/* *************************************************************************************************
 Macros.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@attached(member, names: arbitrary)
internal macro _ExpandStaticKeywords() = #externalMacro(module: "PQMacros", type: "StaticKeywordExpander")

@attached(member, names: arbitrary)
internal macro _ExpandWellknownOperators() = #externalMacro(module: "PQMacros", type: "WellknownOperatorsExpander")


/// A type that is supposed to be used as an argument of `#const` macro.
public struct _MacroConstantExpression: ExpressibleByFloatLiteral,
                                        ExpressibleByIntegerLiteral,
                                        ExpressibleByStringLiteral {
  public typealias FloatLiteralType = Double
  public typealias IntegerLiteralType = Int
  public typealias StringLiteralType = String
  public init(floatLiteral value: FloatLiteralType) {}
  public init(integerLiteral value: IntegerLiteralType) {}
  public init(stringLiteral value: String) {}
}

/// A macro that produces a constructor of some kind of `Expression`.
///
/// Macro              | Expanded
/// -------------------|-------------------------------------------
/// `#const("string")` | `StringConstantExpression("string")`
/// `#const(123)`      | `UnsignedIntegerConstantExpression(123)`
/// `#const(123.45)`   | `UnsignedFloatConstantExpression(123.45)`
///
@freestanding(expression)
public macro const(_ constExpression: _MacroConstantExpression) -> any Expression =
  #externalMacro(module: "PQMacros", type: "ConstantExpressionMacro")
