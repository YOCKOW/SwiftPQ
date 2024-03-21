/* *************************************************************************************************
 ConstantTypeName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a name of constant type.
public protocol ConstantTypeName: SQLTokenSequence {}

/// A type representing a name of numeric.
public enum NumericTypeName: ConstantTypeName {
  /// `INT` type.
  case int

  /// `INTEGER` type.
  case integer

  /// `SMALLINT` type.
  case samllInt

  /// `BIGINT` type.
  case bigInt

  /// `REAL` type.
  case real

  /// `FLOAT` token
  case float(precision: Int? = nil)

  /// `FLOAT` token without precision.
  public static let float: NumericTypeName = .float()

  /// `DOUBLE PRECISION` type.
  case doublePrecision

  public static let double: NumericTypeName = .doublePrecision

  /// `DECIMAL` type.
  case decimal(modifiers: GeneralExpressionList? = nil)

  /// `DECIMAL` type withoug modifiers.
  public static let decimal: NumericTypeName = .decimal()

  public static func decimal(precision: Int) -> NumericTypeName {
    fatalError("Unimplemented.")
  }

  /// `DEC` type.
  case dec(modifiers: GeneralExpressionList? = nil)

  /// `DEC` type without modifiers.
  public static let dec: NumericTypeName = .dec()

  /// `NUMERIC` type.
  case numeric(modifiers: GeneralExpressionList? = nil)

  public static func numeric(precision: Int, scale: Int? = nil) -> NumericTypeName {
    // TODO: `'-' a_expr` must be implemented.
    fatalError("Unimplemented.")
  }

  /// `BOOLEAN` type.
  case boolean

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    switch self {
    case .int:
      return JoinedSQLTokenSequence([SingleToken(.int)])
    case .integer:
      return JoinedSQLTokenSequence([SingleToken(.integer)])
    case .samllInt:
      return JoinedSQLTokenSequence([SingleToken(.smallint)])
    case .bigInt:
      return JoinedSQLTokenSequence([SingleToken(.bigint)])
    case .real:
      return JoinedSQLTokenSequence([SingleToken(.real)])
    case .float(let precision):
      var seqCollection: [any SQLTokenSequence] = [SingleToken(.float)]
      if let precision {
        seqCollection.append(SingleToken(.joiner))
        seqCollection.append(SingleToken(.integer(precision)).parenthesized)
      }
      return JoinedSQLTokenSequence(seqCollection)
    case .doublePrecision:
      return JoinedSQLTokenSequence(SingleToken(.double), SingleToken(.precision))
    case .decimal(let modifiers):
      var seqCollection: [any SQLTokenSequence] = [SingleToken(.decimal)]
      if let modifiers {
        seqCollection.append(SingleToken(.joiner))
        seqCollection.append(modifiers.parenthesized)
      }
      return JoinedSQLTokenSequence(seqCollection)
    case .dec(let modifiers):
      var seqCollection: [any SQLTokenSequence] = [SingleToken(.dec)]
      if let modifiers {
        seqCollection.append(SingleToken(.joiner))
        seqCollection.append(modifiers.parenthesized)
      }
      return JoinedSQLTokenSequence(seqCollection)
    case .numeric(let modifiers):
      var seqCollection: [any SQLTokenSequence] = [SingleToken(.numeric)]
      if let modifiers {
        seqCollection.append(SingleToken(.joiner))
        seqCollection.append(modifiers.parenthesized)
      }
      return JoinedSQLTokenSequence(seqCollection)
    case .boolean:
      return JoinedSQLTokenSequence([SingleToken(.boolean)])
    }
  }
}

/// A name of bit string type, that is described as `ConstBit` in "gram.y".
public enum ConstantBitStringTypeName: ConstantTypeName {
  /// Fixed-length bit string
  case fixed(length: Int? = nil)

  public static let fixed: ConstantBitStringTypeName = .fixed()

  /// Variable-length bit string
  case varying(length: Int? = nil)

  public static let varying: ConstantBitStringTypeName = .varying()



  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    var tokens: [any SQLTokenSequence] = [SingleToken(.bit)]

    func __append(length: Int) {
      tokens.append(SingleToken.joiner)
      tokens.append(SingleToken(.integer(length)).parenthesized)
    }

    switch self {
    case .fixed(let length):
      length.map(__append(length:))
    case .varying(let length):
      tokens.append(SingleToken(.varying))
      length.map(__append(length:))
    }

    return JoinedSQLTokenSequence(tokens)
  }
}
