/* *************************************************************************************************
 StatementTerminator.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Statement terminator (;)
public final class StatementTerminator: SQLTokenSequence {
  public let tokens: [SQLToken] = [.joiner, .semicolon, .newline]
  public static let statementTerminator: StatementTerminator = .init()
}

/// Statement terminator (;)
public let statementTerminator: StatementTerminator = .statementTerminator
