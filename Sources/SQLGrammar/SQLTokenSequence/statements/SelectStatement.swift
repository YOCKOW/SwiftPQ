/* *************************************************************************************************
 SelectStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of a `SELECT` statement.
///
/// In "gram.y", `SelectStmt` is defined as `select_no_parens | select_with_parens`.
/// However, `Parenthesized<SelectStatement>` can represent `select_with_parens` in this module, so
/// `SelectStatement` represents only `select_no_parens`.
public protocol SelectStatement: Statement {}
