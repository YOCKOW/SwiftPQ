/* *************************************************************************************************
 JSONConstructorNullOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public class JSONConstructorNullOptionTokens: Segment {
  public var tokens: Array<SQLToken> { fatalError("Must be overriden.") }
}

private final class NullOnNull: JSONConstructorNullOptionTokens {
  let _tokens: Array<SQLToken> = [.null, .on, .null]
  override var tokens: Array<SQLToken> { _tokens }
  static let nullOnNull: NullOnNull = .init()
}

private final class AbsentOnNull: JSONConstructorNullOptionTokens {
  let _tokens: Array<SQLToken> = [.absent, .on, .null]
  override var tokens: Array<SQLToken> { _tokens }
  static let absentOnNull: AbsentOnNull = .init()
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

  public func makeIterator() -> JSONConstructorNullOptionTokens.Iterator {
    return tokens.makeIterator()
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

  public func makeIterator() -> JSONConstructorNullOptionTokens.Iterator {
    return tokens.makeIterator()
  }
}
