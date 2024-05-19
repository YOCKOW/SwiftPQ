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

| gram.y                | Swift                                 |
|-----------------------|---------------------------------------|
| `attr_name`           | `enum AttributeName`                  |
| `BareColLabel`        | `struct BareColumnLabel`              |
| `ColId`               | `struct ColumnIdentifier`             |
| `ColLabel`            | `struct ColumnLabel`                  |
| `document_or_content` | `enum XMLOption`                      |
| `opt_drop_behavior`   | `enum DropBehavior`                   |
| `extract_arg`         | `struct ExtractFunction.Field`        |
| `type_function_name`  | `struct TypeOrFunctionName`(internal) |
| `unicode_normal_form` | `enum UnicodeNormalizationForm`       |


## Type Names

| gram.y                                         | Swift                              |
|------------------------------------------------|------------------------------------|
| n/a                                            | `protocol ConstantTypeName`        |
| `Bit`                                          | `enum BitStringTypeName`           |
| `Character`                                    | `struct CharacterTypeName`         |
| `ConstBit`                                     | `struct ConstantBitStringTypeName` |
| `ConstCharacter`                               | `struct ConstantCharacterTypeName` |
| `ConstDatetime`                                | `struct ConstantDateTimeTypeName`  |
| `ConstInterval [opt_interval\|'(' Iconst ')']` | `struct ConstantIntervalTypeName`  |
| `GenericType`                                  | `struct GenericTypeName`           |
| `Numeric`                                      | `enum NumericTypeName`             |
| `SimpleTypename`                               | `protocol SimpleTypeName`          |
| `Typename`                                     | `struct TypeName`                  |

## Other Names

| gram.y                 | Swift                                 |
|------------------------|---------------------------------------|
| `any_name`             | `protocol AnyName`                    |
| `func_name`            | `struct FunctionName`                 |
| `object_type_any_name` | `enum ObjectTypeAnyName`              |
| `OptTempTableName`     | `struct TemporaryTableName`           |
| `param_name`           | `struct ParameterName`                |
| `qualified_name`       | `protocol QualifiedName`              |
| n/a                    | `struct CollationName`                |
| n/a                    | `struct DatabaseName`                 |
| n/a                    | `struct SchemaName`                   |
| n/a                    | `struct TableName`                    |

## Clauses

| gram.y                                      | Swift                                  |
|---------------------------------------------|----------------------------------------|
| `alias_clause`                              | `struct AliasClause`                   |
| `opt_asc_desc`                              | `enum SortDirection`                   |
| `opt_collate_clause`                        | `struct CollateClause`                 |
| `filter_clause`                             | `struct FilterClause`                  |
| `opt_frame_clause`                          | `struct FrameClause`                   |
| `func_alias_clause`                         | `struct FunctionAliasClause`           |
| `into_clause`                               | `struct IntoClause`                    |
| `json_array_aggregate_order_by_clause_opt`  | `struct JSONArrayAggregateSortClause`  |
| `json_encoding_clause_opt`                  | `struct JSONEncodingClause`            |
| `json_format_clause_opt`                    | `struct JSONFormatClause`              |
| `json_object_constructor_null_clause_opt`   | `enum JSONObjectConstructorNullOption` |
| `json_output_clause_opt`                    | `struct JSONOutputTypeClause`          |
| `opt_nulls_order`                           | `enum NullOrdering`                    |
| `opt_ordinality`                            | `class WithOrdinalityClause` (private) |
| `over_clause`                               | `struct OverClause`                    |
| `opt_partition_clause`                      | `struct PartitionClause`               |
| `opt_repeatable_clause`                     | `struct RepeatableClause<Seed>`        |
| `sortby`                                    | `struct SortBy<Expression>`            |
| `sort_clause`                               | `struct SortClause`                    |
| `tablesample_clause`                        | `struct TableSampleClause`             |
| `when_clause`                               | `struct WhenClause<Condition, Result>` |
| `opt_window_exclusion_clause`               | `enum WindowExclusionClause`           |
| `within_group_clause`                       | `struct WithinGroupClause`             |


## Expressions

| gram.y                     | Swift                                      |
|----------------------------|--------------------------------------------|
| `a_expr`                   | `protocol GeneralExpression`               |
| `b_expr`                   | `protocol RestrictedExpression`            |
| `c_expr`                   | `protocol ProductionExpression`            |
| `func_application`         | `struct FunctionApplication`               |
| `func_arg_expr`            | `struct FunctionArgumentExpression`        |
| `func_expr`                | `protocol FunctionExpression`              |
| `func_expr_common_subexpr` | `protocol CommonFunctionSubexpression`     |
| `func_expr_windowless`     | `protocol WindowlessFunctionExpression`    |
| `json_aggregate_func`      | `protocol JSONAggregateFunctionExpression` |
| `json_value_expr`          | `struct JSONValueExpression`               |
| `relation_expr`            | `struct RelationExpression`                |
| n/a                        | `protocol ValueExpression`                 |


## Statements

| gram.y                          | Swift                                  |
|---------------------------------|----------------------------------------|
| `DropStmt`                      | `protocol DropStatement`               |
| `DROP object_type_any_name ...` | `protocol DropObjectTypeAnyName`       |
| `DROP TABLE ...`                | `struct DropTable`                     |
| `select_no_parens`              | `protocol BareSelectStatement`         |
| `SelectStmt`                    | `protocol SelectStatement`             |
| `stmt`                          | `protocol Statement`                   |


## Others

| gram.y                 | Swift                                            |
|------------------------|--------------------------------------------------|
| `any_name_list`        | `struct AnyNameList`                             |
| `opt_array_bounds`     | `struct ArrayBoundList`                          |
| `attrs`                | `struct AttributeList`                           |
| `opt_col_def_list`     | `struct ColumnDefinitionList`                    |
| `expr_list`            | `struct GeneralExpressionList`                   |
| `extract_list`         | `struct ExtractFunction._List` (private)         |
| `frame_bound`          | `enum FrameBound`                                |
| `frame_extent`         | `struct FrameExtent`                             |
| `func_arg_list`        | `struct FunctionArgumentList`                    |
| `func_table`           | `struct TableFunction`                           |
| `indirection`          | `struct Indirection`                             |
| `indirection_el`       | `enum Indirection.List.Element`                  |
| `opt_interval`         | `enum IntervalFieldsPhrase`                      |
| `substr_list`          | `struct SubstringFunction.List`                  |
| `TableFuncElement`     | `struct TableFunctionElement`                    |
| `TableFuncElementList` | `struct TableFunctionElementLit`                 |
| `target_el`            | `struct TargetElement`                           |
| `target_list`          | `struct TargetList`                              |
| `trim_list`            | `struct TrimFunction.List`                       |
| `rowsfrom_item`        | `struct TableFunction.RowsFromSyntax.Item`       | 
| `rowsfrom_list`        | `struct TableFunction.RowsFromSyntax.List`       |
| `when_clause_list`     | `struct WhenClauseList`                          |
| `window_specification` | `struct WindowSpecification`                     |


### JSON-related

| gram.y                                    | Swift                                            |
|-------------------------------------------|--------------------------------------------------|
| `json_array_constructor_null_clause_opt`  | `enum JSONArrayConstructorNullOption`            |
| `json_key_uniqueness_constraint_opt`      | `enum JSONKeyUniquenessOption`                   |
| `json_name_and_value`                     | `struct JSONKeyValuePair`                        |
| `json_name_and_value_list`                | `struct JSONKeyValuePairList`                    |
| `json_value_expr_list`                    | `struct JSONValueExpressionList`                 |


### XML-Related

| gram.y                    | Swift                                            |
|---------------------------|--------------------------------------------------|
| `xml_attribute_el`        | `struct XMLAttribute`                            |
| `xml_attribute_list`      | `struct XMLAttributeList`                        |
| `xmlexists_argument`      | `struct XMLPassingArgument`                      |
| `xml_indent_option`       | `enum XMLSerializeFunction.IndentOption`         |
| `xml_passing_mech`        | `enum XMLPassingArgumentMechanism`               |
| `opt_xml_root_standalone` | `enum XMLRootFunction.Standalone`                |
| `xml_root_version`        | `enum XMLRootFunction.Version`                   |
| `xml_whitespace_option`   | `enum XMLWhitespaceOption`                       |


