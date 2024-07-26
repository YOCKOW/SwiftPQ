/* *************************************************************************************************
 TypedTableColumnDefinition.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private final class WithOptions: Segment {
  let tokens: Array<Token> = [.with, .options]
  private init() {}
  static let withOptions: WithOptions = .init()
}

/// Column definition used in typed table. This is described as `columnOptions` in "gram.y".
public struct TypedTableColumnDefinition: TokenSequenceGenerator {
  /// Column name.
  public let name: ColumnIdentifier

  /// A boolean value that indicates whether or not `WITH OPTIONS` tokens are omitted.
  public var omitWithOptionsTokens: Bool

  public let constraints: ColumnQualifierList?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      name.asSequence,
      omitWithOptionsTokens ? nil : WithOptions.withOptions,
      constraints
    )
  }

  public init(name: ColumnIdentifier, constraints: ColumnQualifierList? = nil) {
    self.name = name
    self.omitWithOptionsTokens = true
    self.constraints = constraints
  }

  public init(name: ColumnIdentifier, withOptions constraints: ColumnQualifierList?) {
    self.name = name
    self.omitWithOptionsTokens = false
    self.constraints = constraints
  }

  public init(name: ColumnIdentifier, constraints: [ColumnQualifierList.Constraint]) {
    self.init(name: name, constraints: .constraints(constraints))
  }

  public init(name: ColumnIdentifier, withOptions constraints: [ColumnQualifierList.Constraint]) {
    self.init(name: name, withOptions: .constraints(constraints))
  }
}
