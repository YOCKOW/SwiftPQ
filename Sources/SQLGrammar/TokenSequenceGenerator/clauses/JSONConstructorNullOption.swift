/* *************************************************************************************************
 JSONConstructorNullOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public class JSONConstructorNullOptionTokens: Segment, TokenSequence {
  public let tokens: Array<SQLToken>
  fileprivate init(_ tokens: Array<SQLToken>) { self.tokens = tokens }
}

private final class NullOnNull: JSONConstructorNullOptionTokens {
  static let nullOnNull: NullOnNull = .init([.null, .on, .null])
}

private final class AbsentOnNull: JSONConstructorNullOptionTokens {
  static let absentOnNull: AbsentOnNull = .init([.absent, .on, .null])
}

/// An option whether or not `NULL` should be ignored while JSON object construction.
///
/// This type is described as `json_object_constructor_null_clause_opt` in "gram.y".
public enum JSONObjectConstructorNullOption: Clause {
  case nullOnNull
  case absentOnNull

  public var tokens: JSONConstructorNullOptionTokens {
    switch self {
    case .nullOnNull:
      return NullOnNull.nullOnNull
    case .absentOnNull:
      return AbsentOnNull.absentOnNull
    }
  }
}

/// An option whether or not `NULL` should be ignored while JSON array construction.
///
/// This type is described as `json_array_constructor_null_clause_opt` in "gram.y".
public enum JSONArrayConstructorNullOption: Clause {
  case nullOnNull
  case absentOnNull

  public var tokens: JSONConstructorNullOptionTokens {
    switch self {
    case .nullOnNull:
      return NullOnNull.nullOnNull
    case .absentOnNull:
      return AbsentOnNull.absentOnNull
    }
  }
}
