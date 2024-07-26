/* *************************************************************************************************
 JSONOutputTypeClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause to specify the type of JSON output, described as `json_output_clause_opt` in "gram.y".
public struct JSONOutputTypeClause: Clause {
  public let typeName: TypeName

  public let format: JSONFormatClause?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      SingleToken.returning,
      typeName,
      format
    )
  }

  /// Creates a JSON output type clause.
  ///
  /// - parameters:
  ///   * typeName: Expected to be one of `json`, `jsonb`, `bytea`,
  ///               a character string type (`text`, `char`, or `varchar`),
  ///               or a type for which there is a cast from `json` to that type.
  ///               See [table 9.47 in official documentation](https://www.postgresql.org/docs/16/functions-json.html#FUNCTIONS-JSON-CREATION-TABLE).
  public init(typeName: TypeName, format: JSONFormatClause? = nil) {
    self.typeName = typeName
    self.format = format
  }
}
