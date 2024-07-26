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
public struct _MacroConstantExpression: ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public init(stringLiteral value: String) {}
}

/// A macro that produces a constructor of some kind of `Expression`.
///
/// Macro              | Expanded
/// -------------------|--------------------------------------
/// `#const("string")` | `StringConstantExpression("string")`
///
@freestanding(expression)
public macro const(_ constExpression: _MacroConstantExpression) -> any Expression =
  #externalMacro(module: "PQMacros", type: "ConstantExpressionMacro")
