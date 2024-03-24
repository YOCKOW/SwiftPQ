/* *************************************************************************************************
 SelectStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Representation of a `SELECT` statement, that is described as `SelectStmt` in "gram.y".
public protocol SelectStatement: Statement {}

// Represents `select_with_parens`.
extension Parenthesized: Statement, SelectStatement where EnclosedTokens: SelectStatement {}
