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


/// A macro that converts a string literal to a `StringConstantExpression` constructor.
@freestanding(expression)
public macro const(_ string: String) -> StringConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "ConstantExpressionMacro"
)

/// A macro that converts an integer literal to a `UnsignedIntegerConstantExpression` constructor,
/// or `+`/`-` operator followed by an integer literal to a
/// `UnaryPrefix[Plus|Minus]OperatorInvocation` constructor.
@freestanding(expression)
public macro const(_: Int) -> any (
  SignedIntegerConstantExpression & GeneralExpression & RestrictedExpression
) = #externalMacro(
  module: "PQMacros",
  type: "ConstantExpressionMacro"
)

/// A macro that converts an integer literal to a `UnsignedIntegerConstantExpression` constructor.
@freestanding(expression)
public macro const(_: UInt64) -> UnsignedIntegerConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "ConstantExpressionMacro"
)

/// A macro that converts a float literal to a `UnsignedFloatConstantExpression` constructor,
/// or `+`/`-` operator followed by a float literal to a
/// `UnaryPrefix[Plus|Minus]OperatorInvocation` constructor.
@freestanding(expression)
public macro const(
  _ integer: any (ExpressibleByFloatLiteral & AdditiveArithmetic)
) -> any SignedFloatConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "ConstantExpressionMacro"
)
