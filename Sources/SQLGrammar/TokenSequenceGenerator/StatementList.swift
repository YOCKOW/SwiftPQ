/* *************************************************************************************************
 StatementList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// List of statements. This is described as `stmtmulti` in "gram.y".
public struct StatementList: TokenSequenceGenerator,
                             InitializableWithNonEmptyList,
                             ExpressibleByArrayLiteral {
  public var statements: NonEmptyList<any TopLevelStatement>

  @inlinable
  public var tokens: JoinedTokenSequence {
    return statements.map({ $0 as any TokenSequenceGenerator }).joined(separator: statementTerminator)
  }

  public init(_ statements: NonEmptyList<any TopLevelStatement>) {
    self.statements = statements
  }

  @inlinable
  public init<FirstStatement, each OptionalStatement>(
    _ firstStatement: FirstStatement,
    _ optionalStatement: repeat each OptionalStatement
  ) where FirstStatement: TopLevelStatement, repeat each OptionalStatement: TopLevelStatement {
    self.init(firstStatement)
    repeat (self.statements.append(each optionalStatement))
  }
}
