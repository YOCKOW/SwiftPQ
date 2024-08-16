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


// MARK: - BooleanMacro

/// A macro that expands `BooleanConstantExpression` instance expression.
@freestanding(expression)
public macro bool(_ bool: Bool) -> BooleanConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "BooleanMacro"
)

/// A macro that expands `BooleanConstantExpression.true` expression.
@freestanding(expression)
public macro TRUE() -> BooleanConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "BooleanMacro"
)

/// A macro that expands `BooleanConstantExpression.false` expression.
@freestanding(expression)
public macro FALSE() -> BooleanConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "BooleanMacro"
)


// MARK: - ConstantExpressionMacro

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
  _ float: any (ExpressibleByFloatLiteral & AdditiveArithmetic)
) -> any (
  SignedFloatConstantExpression & GeneralExpression & RestrictedExpression
) = #externalMacro(
  module: "PQMacros",
  type: "ConstantExpressionMacro"
)

/// A macro that expands `BooleanConstantExpression` instance expression.
@freestanding(expression)
public macro const(_ bool: Bool) -> BooleanConstantExpression = #externalMacro(
  module: "PQMacros",
  type: "ConstantExpressionMacro"
)

// MARK: - PositionalParameterMacro

///  A macro that converts an integer literal to a `Token.PositionalParameter` constructor.
@freestanding(expression)
public macro param(_ pos: UInt) -> Token.PositionalParameter = #externalMacro(
  module: "PQMacros",
  type: "PositionalParameterMacro"
)

///  A macro that converts an integer literal to a `PositionalParameterExpression` constructor.
@freestanding(expression)
public macro paramExpr(_ pos: UInt) -> PositionalParameterExpression = #externalMacro(
  module: "PQMacros",
  type: "PositionalParameterMacro"
)
