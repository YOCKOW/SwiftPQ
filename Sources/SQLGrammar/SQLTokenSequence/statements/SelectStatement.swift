/* *************************************************************************************************
 SelectStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of a `SELECT` statement, that is described as `SelectStmt` in "gram.y".
public protocol SelectStatement: ParenthesizableStatement {}

/// Representation of `SELECT` statement without any parentheses,
/// that is described as `select_no_parens` in "gram.y".
public protocol BareSelectStatement: SelectStatement {}

// Represents `select_with_parens`.
extension Parenthesized: SelectStatement where EnclosedTokens: SelectStatement {}
