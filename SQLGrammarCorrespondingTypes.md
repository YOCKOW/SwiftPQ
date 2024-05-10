# `SQLGrammar` module.

This package contains a module named `SQLGrammar` that is the backend of `SwiftPQ` to generate SQL commands in the *Swifty* way.

Here are lists that show which Swift type corresponds to a symbol in "gram.y". That is not necessarily one-on-one correspondence.

# The Lists

## Operators

| gram.y                          | Swift                                 |
|---------------------------------|---------------------------------------|
| `all_Op`                        | `protocol OperatorTokenConvertible`   |
| `any_operator`                  | `struct LabeledOperator`              |
| `MathOp`                        | `struct MathOperator`                 |
| `Op`                            | `struct GeneralOperator`              |
| `OPERATOR '(' any_operator ')'` | `struct OperatorConstructor`          |
| `qual_all_Op`                   | `struct QualifiedOperator`            |
| `qual_Op`                       | `struct QualifiedGeneralOperator`     |

## One-token symbols

| gram.y               | Swift                                 |
|----------------------|---------------------------------------|
| `attr_name`          | `enum AttributeName`                  |
| `BareColLabel`       | `struct BareColumnLabel`              |
| `ColId`              | `struct ColumnIdentifier`             |
| `ColLabel`           | `struct ColumnLabel`                  |
| `opt_drop_behavior`  | `enum DropBehavior`                   |
| `type_function_name` | `struct TypeOrFunctionName`(internal) |


## Constant Types

| gram.y               | Swift                                 |
|----------------------|---------------------------------------|
| n/a                  | `protocol ConstantTypeName`           |
| `ConstBit`           | `enum ConstantBitStringTypeName`      |
| `ConstCharacter`     | `struct ConstantCharacterTypeName`    |
| `ConstDatetime`      | `struct ConstantDateTimeTypeName`     |
| `Numeric`            | `enum NumericTypeName`                |

## Names

| gram.y                 | Swift                                 |
|------------------------|---------------------------------------|
| `any_name`             | `protocol AnyName`                    |
| `func_name`            | `struct FunctionName`                 |
| `object_type_any_name` | `enum ObjectTypeAnyName`              |
| `OptTempTableName`     | `struct TemporaryTableName`           |
| `param_name`           | `struct ParameterName`                |
| `qualified_name`       | `protocol QualifiedName`              |
| n/a                    | `struct DatabaseName`                 |
| n/a                    | `struct SchemaName`                   |
| n/a                    | `struct TableName`                    |

## Clauses

| gram.y               | Swift                                  |
|----------------------|----------------------------------------|
| `alias_clause`       | `struct AliasClause`                   |
| `into_clause`        | `struct IntoClause`                    |
| `opt_asc_desc`       | `enum SortDirection`                   |
| `opt_nulls_order`    | `enum NullOrdering`                    |
| `sortby`             | `struct SortBy<Expression>`            |
| `sort_clause`        | `struct SortClause`                    |
| `when_clause`        | `struct WhenClause<Condition, Result>` | 
| `when_clause_list`   | `struct WhenClauseList`                |


## Expressions

| gram.y               | Swift                                  |
|----------------------|----------------------------------------|
| `a_expr`             | `protocol GeneralExpression`           |
| `b_expr`             | `protocol RestrictedExpression`        |
| `c_expr`             | `protocol ProductionExpression`        |
| `func_arg_expr`      | `struct FunctionArgumentExpression`    |
| n/a                  | `protocol ValueExpression`             |


## Statements

| gram.y                          | Swift                                  |
|---------------------------------|----------------------------------------|
| `DropStmt`                      | `protocol DropStatement`               |
| `DROP object_type_any_name ...` | `protocol DropObjectTypeAnyName`       |
| `DROP TABLE ...`                | `struct DropTable`                     |
| `SelectStmt`                    | `protocol SelectStatement`             |
| `stmt`                          | `protocol Statement`                   |


## Others

| gram.y               | Swift                                  |
|----------------------|----------------------------------------|
| `any_name_list`      | `struct AnyNameList`                   |
| `attrs`              | `struct AttributeList`                 |
| `expr_list`          | `struct GeneralExpressionList`         |
| `func_arg_list`      | `struct FunctionArgumentList`          |
| `indirection`        | `struct Indirection`                   |
| `indirection_el`     | `enum Indirection.List.Element`        |
| `opt_interval`       | `enum IntervalFieldsPhrase`            |
| `target_el`          | `struct TargetElement`                 |
| `target_list`        | `struct TargetList`                    |


