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
| `subquery_Op`                   | `struct SubqueryOperator`             |

## One-token symbols

| gram.y                | Swift                                  |
|-----------------------|----------------------------------------|
| `attr_name`           | `enum AttributeName`                   |
| `BareColLabel`        | `struct BareColumnLabel`               |
| `ColId`               | `struct ColumnIdentifier`              |
| `ColLabel`            | `struct ColumnLabel`                   |
| `document_or_content` | `enum XMLOption`                       |
| `opt_drop_behavior`   | `enum DropBehavior`                    |
| `extract_arg`         | `struct ExtractFunction.Field`         |
| `first_or_next`       | `enum LimitClause.FetchClause.Keyword` |
| `row_or_rows`         | `enum LimitClause.FetchClause.Unit`    |
| `set_quantifier`      | `enum SetQuantifier`                   |
| `sub_type`            | `enum SatisfyExpression.Kind`          |
| `TableLikeOption`     | `enum TableLikeOption`                 |
| `type_function_name`  | `struct TypeOrFunctionName`(internal)  |
| `unicode_normal_form` | `enum UnicodeNormalizationForm`        |


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
| `name`                 | `struct Name`                         |
| `object_type_any_name` | `enum ObjectTypeAnyName`              |
| `OptTempTableName`     | `struct TemporaryTableName`           |
| `param_name`           | `struct ParameterName`                |
| `qualified_name`       | `protocol QualifiedName`              |
| n/a                    | `struct CollationName`                |
| n/a                    | `struct DatabaseName`                 |
| n/a                    | `struct SchemaName`                   |
| n/a                    | `struct TableName`                    |

## Clauses

| gram.y                                      | Swift                                                     |
|---------------------------------------------|-----------------------------------------------------------|
| `alias_clause`                              | `struct AliasClause`                                      |
| `opt_alias_clause_for_join_using`           | `class JoinCondition._AliasClauseForJoinUsing` (private)  |
| `opt_asc_desc`                              | `enum SortDirection`                                      |
| `opt_collate_clause`                        | `struct CollateClause`                                    |
| `cube_clause`                               | `struct CubeClause`                                       |
| `opt_cycle_clause`                          | `struct CycleClause`                                      |
| `distinct_clause`                           | `struct DistinctClause`                                   |
| `filter_clause`                             | `struct FilterClause`                                     |
| `for_locking_clause`                        | `struct LockingClause`                                    |
| `opt_frame_clause`                          | `struct FrameClause`                                      |
| `from_clause`                               | `struct FromClause`                                       |
| `func_alias_clause`                         | `struct FunctionAliasClause`                              |
| `group_clause`                              | `struct GroupClause`                                      |
| `grouping_sets_clause`                      | `struct GroupingSetsClause`                               |
| `having_clause`                             | `struct HavingClause`                                     |
| `into_clause`                               | `struct IntoClause`                                       |
| `json_array_aggregate_order_by_clause_opt`  | `struct JSONArrayAggregateSortClause`                     |
| `json_encoding_clause_opt`                  | `struct JSONEncodingClause`                               |
| `json_format_clause_opt`                    | `struct JSONFormatClause`                                 |
| `json_object_constructor_null_clause_opt`   | `enum JSONObjectConstructorNullOption`                    |
| `json_output_clause_opt`                    | `struct JSONOutputTypeClause`                             |
| `limit_clause`                              | `struct LimitClause`                                      |
| `opt_nulls_order`                           | `enum NullOrdering`                                       |
| `offset_clause`                             | `struct OffsetClause`                                     |
| `opt_ordinality`                            | `class WithOrdinalityClause` (private)                    |
| `over_clause`                               | `struct OverClause`                                       |
| `opt_partition_clause`                      | `struct PartitionClause`                                  |
| `opt_repeatable_clause`                     | `struct RepeatableClause<Seed>`                           |
| `rollup_clause`                             | `struct RollUpClause`                                     |
| `opt_search_clause`                         | `struct SearchClause`                                     |
| `select_clause`                             | `struct SelectClause`                                     |
| `select_limit`                              | `struct SelectLimitClause`                                |
| `sortby`                                    | `struct SortBy<Expression>`                               |
| `sort_clause`                               | `struct SortClause`                                       |
| `TableLikeClause`                           | `struct TableLikeClause`                                  |
| `tablesample_clause`                        | `struct TableSampleClause`                                |
| `values_clause`                             | `struct ValuesClause`                                     |
| `when_clause`                               | `struct WhenClause<Condition, Result>`                    |
| `where_clause`                              | `struct WhereClause`                                      |
| `window_clause`                             | `struct WindowClause`                                     |
| `opt_window_exclusion_clause`               | `enum WindowExclusionClause`                              |
| `with_clause`                               | `struct WithClause`                                       |
| `within_group_clause`                       | `struct WithinGroupClause`                                |


## Expressions

| gram.y                                                                  | Swift                                          |
|-------------------------------------------------------------------------|------------------------------------------------|
| `a_expr`                                                                | `protocol GeneralExpression`                   |
| `a_expr AND a_expr`                                                     | `struct BinaryInfixAndOperatorInvocation`      |
| `a_expr AT TIME ZONE a_expr`                                            | `struct AtTimeZoneOperatorInvocation`          |
| `a_expr BETWEEN {opt_asymmetric \| SYMMETRIC} b_expr AND a_expr`        | `struct BetweenExpression`                     |
| `a_expr COLLATE any_name`                                               | `struct CollationExpression`                   |
| `a_expr ILIKE a_expr [ESCAPE a_expr]`                                   | `struct CaseInsensitiveLikeExpression`         |
| `a_expr IN_P in_expr`                                                   | `struct InExpression`                          |
| `a_expr IS FALSE_P`                                                     | `struct IsFalseExpression`                     |
| `a_expr IS json_predicate_type_constraint ...`                          | `struct IsJSONTypeExpression`                  | 
| `a_expr IS [unicode_normal_form] NORMALIZED`                            | `struct IsNormalizedExpression`                |
| `a_expr IS NOT FALSE_P`                                                 | `struct IsNotFalseExpression`                  |
| `a_expr IS NOT json_predicate_type_constraint ...`                      | `struct IsNotJSONTypeExpression`               |
| `a_expr IS NOT [unicode_normal_form] NORMALIZED`                        | `struct IsNotNormalizedExpression`             |
| `a_expr {IS NOT NULL_P \| NOTNULL}`                                     | `struct IsNotNullExpression`                   |
| `a_expr IS NOT TRUE_P`                                                  | `struct IsNotTrueExpression`                   |
| `a_expr IS NOT UNKNOWN`                                                 | `struct IsNotUnknownExpression`                |
| `a_expr {IS NULL_P \| ISNULL}`                                          | `struct IsNullExpression`                      |
| `a_expr IS TRUE_P`                                                      | `struct IsTrueExpression`                      |
| `a_expr IS UNKNOWN`                                                     | `struct IsUnknownExpression`                   |
| `a_expr LIKE a_expr [ESCAPE a_expr]`                                    | `struct LikeExpression`                        |
| `a_expr NOT_LA BETWEEN {opt_asymmetric \| SYMMETRIC} b_expr AND a_expr` | `struct NotBetweenExpression`                  |
| `a_expr NOT ILIKE a_expr [ESCAPE a_expr]`                               | `struct NotCaseInsensitiveLikeExpression`      |
| `a_expr NOT_LA IN_P in_expr`                                            | `struct NotInExpression`                       |
| `a_expr NOT LIKE a_expr [ESCAPE a_expr]`                                | `struct NotLikeExpression`                     |
| `a_expr NOT SIMILAR TO a_expr [ESCAPE a_expr]`                          | `struct NotSimilarToExpression`                |
| `a_expr OR a_expr`                                                      | `struct BinaryInfixOrOperatorInvocation`       |
| `a_expr SIMILAR TO a_expr [ESCAPE a_expr]`                              | `struct SimilarToExpression`                   |
| `a_expr subquery_Op sub_type {select_with_parens \| '(' a_expr ')'}`    | `struct SatisfyExpression`                     |
| `AexprConst`                                                            | `protocol ConstantExpression`                  |
| `ARRAY {select_with_parens \| array_expr}`                              | `struct ArrayConstructorExpression`            |
| `array_expr`                                                            | `struct ArrayConstructorExpression.Subscript`  |
| `b_expr`                                                                | `protocol RestrictedExpression`                |
| `c_expr`                                                                | `protocol ProductionExpression`                |
| `common_table_expr`                                                     | `struct CommonTableExpression`                 |
| `DEFAULT` (as expression)                                               | `struct DefaultExpression`                     |
| `EXISTS select_with_parens`                                             | `struct ExistsExpression`                      |
| `explicit_row`                                                          | `struct RowConstructorExpression`              |
| `func_application`                                                      | `struct FunctionApplication`                   |
| `func_arg_expr`                                                         | `struct FunctionArgumentExpression`            |
| `func_expr`                                                             | `protocol FunctionExpression`                  |
| `func_expr_common_subexpr`                                              | `protocol CommonFunctionSubexpression`         |
| `func_expr_windowless`                                                  | `protocol WindowlessFunctionExpression`        |
| `GROUPING '(' expr_list ')'`                                            | `struct GroupingExpression`                    |
| `implicit_row`                                                          | `struct ImplicitRowConstructorExpression`      |
| `joined_table`                                                          | `protocol JoinedTableExpression`               |
| `json_aggregate_func`                                                   | `protocol JSONAggregateFunctionExpression`     |
| `json_value_expr`                                                       | `struct JSONValueExpression`                   |
| `NOT a_expr`                                                            | `struct UnaryPrefixNotOperatorInvocation`      |
| `relation_expr`                                                         | `struct RelationExpression`                    |
| `row`                                                                   | `struct RowExpression`                         |
| `row OVERLAPS row`                                                      | `struct BinaryInfixOverlapsOperatorInvocation` |
| `select_with_parens indirection`                                        | `struct SelectExpression`                      |
| `table_ref`                                                             | `protocol TableReferenceExpression`            |
| `UNIQUE opt_unique_null_treatment select_with_parens`                   | `struct UniquePredicateExpression`             |
| `xmltable`                                                              | `struct XMLTableExpression`                    |
| n/a                                                                     | `protocol ValueExpression`                     |


### Expressions common to `a_expr` and `b_expr`

(In this list, `a/b_expr` means `a_expr` or `b_expr`.)

| gram.y                                   | Swift                                                      |
|------------------------------------------|------------------------------------------------------------|
| `a/b_expr TYPECAST Typename`             | `struct BinaryInfixTypeCastOperatorInvocation`             |
| `a/b_expr '+' a/b_expr`                  | `struct BinaryInfixPlusOperatorInvocation`                 |
| `a/b_expr '-' a/b_expr`                  | `struct BinaryInfixMinusOperatorInvocation`                |
| `a/b_expr '*' a/b_expr`                  | `struct BinaryInfixMultiplyOperatorInvocation`             |
| `a/b_expr '/' a/b_expr`                  | `struct BinaryInfixDivideOperatorInvocation`               |
| `a/b_expr '%' a/b_expr`                  | `struct BinaryInfixModuloOperatorInvocation`               |
| `a/b_expr '^' a/b_expr`                  | `struct BinaryInfixExponentOperatorInvocation`             |
| `a/b_expr '<' a/b_expr`                  | `struct BinaryInfixLessThanOperatorInvocation`             |
| `a/b_expr '>' a/b_expr`                  | `struct BinaryInfixGreaterThanOperatorInvocation`          |
| `a/b_expr '=' a/b_expr`                  | `struct BinaryInfixEqualToOperatorInvocation`              |
| `a/b_expr '<=' a/b_expr`                 | `struct BinaryInfixLessThanOrEqualToOperatorInvocation`    |
| `a/b_expr '>=' a/b_expr`                 | `struct BinaryInfixGreaterThanOrEqualToOperatorInvocation` |
| `a/b_expr '<>' a/b_expr`                 | `struct BinaryInfixNotEqualToOperatorInvocation`           |
| `a/b_expr qual_Op a/b_expr`              | `struct BinaryInfixQualifiedGeneralOperatorInvocation`     |
| `qual_Op a/b_expr`                       | `struct UnaryPrefixQualifiedGeneralOperatorInvocation`     |
| `a/b_expr IS DISTINCT FROM a/b_expr`     | `struct IsDistinctFromExpression`                          |
| `a/b_expr IS DOCUMENT_P`                 | `struct IsDocumentExpression`                              |
| `a/b_expr IS NOT DISTINCT FROM a/b_expr` | `struct IsNotDistinctFromExpression`                       |
| `a/b_expr IS NOT DOCUMENT_P`             | `struct IsNotDocumentExpression`                           |


## Statements

| gram.y                          | Swift                                  |
|---------------------------------|----------------------------------------|
| `DeleteStmt`                    | `struct DeleteStatement`               |
| `DropStmt`                      | `protocol DropStatement`               |
| `DROP object_type_any_name ...` | `protocol DropObjectTypeAnyName`       |
| `DROP TABLE ...`                | `struct DropTable`                     |
| `InsertStmt`                    | `struct InsertStatement`               |
| `PreparableStmt`                | `protocol PreparableStatement`         |
| `select_no_parens`              | `protocol BareSelectStatement`         |
| `SelectStmt`                    | `protocol SelectStatement`             |
| `simple_select`                 | `protocol SimpleSelectStatement`       |
| `stmt`                          | `protocol Statement`                   |
| `UpdateStmt`                    | `struct UpdateStatement`               |


## Others

| gram.y                      | Swift                                              |
|-----------------------------|----------------------------------------------------|
| `any_name_list`             | `struct AnyNameList`                               |
| `opt_array_bounds`          | `struct ArrayBoundList`                            |
| `array_expr_list`           | `struct ArrayConstructorExpression.Subscript.List` |
| `attrs`                     | `struct AttributeList`                             |
| `opt_col_def_list`          | `struct ColumnDefinitionList`                      |
| `columnElem`                | `struct ColumnListElement`                         |
| `columnList`                | `struct ColumnList`                                |
| `cte_list`                  | `struct CommonTableExpressionList`                 |
| `empty_grouping_set`        | `class EmptyGroupingSet`                           |
| `expr_list`                 | `struct GeneralExpressionList`                     |
| `extract_list`              | `struct ExtractFunction._List` (private)           |
| `for_locking_item`          | `struct LockingMode`                               |
| `for_locking_items`         | `struct LockingModeList`                           |
| `for_locking_strength`      | `enum LockingStrength`                             |
| `frame_bound`               | `enum FrameBound`                                  |
| `frame_extent`              | `struct FrameExtent`                               |
| `from_list`                 | `struct FromList`                                  |
| `func_arg_list`             | `struct FunctionArgumentList`                      |
| `func_table`                | `struct TableFunction`                             |
| `group_by_item`             | `struct GroupingElement`                           |
| `group_by_list`             | `struct GroupingList`                              |
| `indirection`               | `struct Indirection`                               |
| `indirection_el`            | `enum Indirection.List.Element`                    |
| `in_expr`                   | `struct InExpression.Subquery`                     |
| `opt_interval`              | `enum IntervalFieldsPhrase`                        |
| `join_type`                 | `enum JoinType`                                    |
| `join_qual`                 | `enum JoinCondition`                               |
| `locked_rels_list`          | `struct LockedRelationList`                        |
| `name_list`                 | `struct NameList`                                  |
| `opt_name_list`             | `enum OptionalNameList`                            |
| `opt_nowait_or_skip`        | `enum LockingWaitOption`                           |
| `OptTemp`                   | `enum TemporarinessOption`                         |
| `qualified_name_list`       | `struct QualifiedNameList<Q>`                      |
| `substr_list`               | `struct SubstringFunction.List`                    |
| `TableFuncElement`          | `struct TableFunctionElement`                      |
| `TableFuncElementList`      | `struct TableFunctionElementList`                  |
| `TableLikeOptionList`       | `struct TableLikeOptionList`                       |
| `target_el`                 | `struct TargetElement`                             |
| `target_list`               | `struct TargetList`                                |
| `trim_list`                 | `struct TrimFunction.List`                         |
| `rowsfrom_item`             | `struct TableFunction.RowsFromSyntax.Item`         | 
| `rowsfrom_list`             | `struct TableFunction.RowsFromSyntax.List`         |
| `select_fetch_first_value`  | `struct LimitClause.FetchClause.RowCount`          |
| `select_limit_value`        | `enum SelectLimitValue`                            |
| `select_offset_value`       | `struct SelectOffsetValue`                         |
| `opt_unique_null_treatment` | `enum NullTreatment`                               |
| `when_clause_list`          | `struct WhenClauseList`                            |
| `window_definition`         | `struct WindowDefinition`                          |
| `window_definition_list`    | `struct WindowDefinitionList`                      |
| `window_specification`      | `struct WindowSpecification`                       |


### JSON-related

| gram.y                                    | Swift                                            |
|-------------------------------------------|--------------------------------------------------|
| `json_array_constructor_null_clause_opt`  | `enum JSONArrayConstructorNullOption`            |
| `json_key_uniqueness_constraint_opt`      | `enum JSONKeyUniquenessOption`                   |
| `json_name_and_value`                     | `struct JSONKeyValuePair`                        |
| `json_name_and_value_list`                | `struct JSONKeyValuePairList`                    |
| `json_predicate_type_constraint`          | `enum JSONPredicateType`                         |
| `json_value_expr_list`                    | `struct JSONValueExpressionList`                 |


### XML-Related

| gram.y                        | Swift                                                   |
|-------------------------------|---------------------------------------------------------|
| `xml_attribute_el`            | `struct XMLAttribute`                                   |
| `xml_attribute_list`          | `struct XMLAttributeList`                               |
| `xmlexists_argument`          | `struct XMLPassingArgument`                             |
| `xml_indent_option`           | `enum XMLSerializeFunction.IndentOption`                |
| `xml_namespace_el`            | `struct XMLNamespaceListElement`                        |
| `xml_namespace_list`          | `struct XMLNamespaceList`                               |
| `xml_passing_mech`            | `enum XMLPassingArgumentMechanism`                      |
| `opt_xml_root_standalone`     | `enum XMLRootFunction.Standalone`                       |
| `xml_root_version`            | `enum XMLRootFunction.Version`                          |
| `xmltable_column_el`          | `struct XMLTableExpression.ColumnsClause.ColumnElement` |
| `xmltable_column_list`        | `struct XMLTableExpression.ColumnsClause.ColumnList`    |
| `xmltable_column_option_el`   | `enum XMLTableExpression.ColumnsClause.Option`          |
| `xmltable_column_option_list` | `struct XMLTableExpression.ColumnsClause.OptionList`    |
| `xml_whitespace_option`       | `enum XMLWhitespaceOption`                              |


