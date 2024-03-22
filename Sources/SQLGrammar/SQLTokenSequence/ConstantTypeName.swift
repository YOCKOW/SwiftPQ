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

/// A name of constant character, that is described as `ConstCharacter` in "gram.y".
public struct ConstantCharacterTypeName: ConstantTypeName {
  public enum CharacterType: SQLTokenSequence {
    case character
    case char
    case varchar
    case nationalCharacter
    case nationalChar
    case nchar

    fileprivate var canBeVarying: Bool {
      switch self {
      case .varchar:
        return false
      default:
        return true
      }
    }

    public var tokens: Array<SQLToken> {
      switch self {
      case .character:
        return [.character]
      case .char:
        return [.char]
      case .varchar:
        return [.varchar]
      case .nationalCharacter:
        return [.national, .character]
      case .nationalChar:
        return [.national, .char]
      case .nchar:
        return [.nchar]
      }
    }
  }
  
  public let type: CharacterType

  public let varying: Bool

  private let length: Int?

  public var tokens: JoinedSQLTokenSequence {
    var seqCollection: [any SQLTokenSequence] = [type]
    if varying {
      seqCollection.append(SingleToken(.varying))
    }
    if let length = self.length {
      seqCollection.append(SingleToken.joiner)
      seqCollection.append(SingleToken(.integer(length)).parenthesized)
    }
    return JoinedSQLTokenSequence(seqCollection)
  }

  private init(type: CharacterType, varying: Bool, length: Int?) {
    assert(!varying || type.canBeVarying, "'VARYING' is not available.")
    self.type = type
    self.varying = varying
    self.length = length
  }

  /// Create `CHARACTER` type.
  public static func character(
    varying: Bool = false,
    length: Int? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .character, varying: varying, length: length)
  }

  /// Create fixed-length `CHARACTER` type without specifying length.
  public static let character: ConstantCharacterTypeName = .character()

  /// Create `CHAR` type.
  public static func char(
    varying: Bool = false,
    length: Int? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .char, varying: varying, length: length)
  }

  /// Create fixed-length `CHAR` type without specifying length.
  public static let char: ConstantCharacterTypeName = .char()

  /// Create `VARCHAR` type.
  public static func varchar(length: Int? = nil) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .varchar, varying: false, length: length)
  }

  /// Create fixed-length `VARCHAR` type without specifying length.
  public static let varchar: ConstantCharacterTypeName = .varchar()

  /// Create `NATIONAL CHARACTER` type.
  public static func nationalCharacter(
    varying: Bool = false,
    length: Int? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .nationalCharacter, varying: varying, length: length)
  }

  /// Create fixed-length `NATIONAL CHARACTER` type without specifying length.
  public static let nationalCharacter: ConstantCharacterTypeName = .nationalCharacter()

  /// Create `NATIONAL CHAR` type.
  public static func nationalChar(
    varying: Bool = false,
    length: Int? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .nationalChar, varying: varying, length: length)
  }

  /// Create fixed-length `NATIONAL CHAR` type without specifying length.
  public static let nationalChar: ConstantCharacterTypeName = .nationalChar()

  /// Create `NCHAR` type.
  public static func nchar(
    varying: Bool = false,
    length: Int? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .nchar, varying: varying, length: length)
  }

  /// Create fixed-length `NCHAR` type without specifying length.
  public static let nchar: ConstantCharacterTypeName = .nchar()
}

private final class WithTimeZone: Segment {
  let tokens: [SQLToken] = [.with, .time, .zone]
  static let withTimeZone: WithTimeZone = .init()
}

private final class WithoutTimeZone: Segment {
  let tokens: [SQLToken] = [.without, .time, .zone]
  static let withoutTimeZone: WithoutTimeZone = .init()
}

/// A name of date-time type, that is described as `ConstantDatetime` in "gram.y".
public struct ConstantDateTimeTypeName: ConstantTypeName {
  public enum DateTimeType {
    case timestamp
    case time

    var token: SQLToken {
      switch self {
      case .timestamp:
        return .timestamp
      case .time:
        return .time
      }
    }
  }

  public let type: DateTimeType

  /// The number of fractional digits.
  public let precision: Int?

  public let withTimeZone: Bool?

  public var tokens: JoinedSQLTokenSequence {
    var seqCollection: [any SQLTokenSequence] = []
    if let precision {
      seqCollection.append(
        SingleToken(type.token).followedBy(parenthesized: SingleToken.integer(precision))
      )
    } else {
      seqCollection.append(SingleToken(type.token))
    }
    if let withTimeZone {
      if withTimeZone {
        seqCollection.append(WithTimeZone.withTimeZone)
      } else {
        seqCollection.append(WithoutTimeZone.withoutTimeZone)
      }
    }
    return JoinedSQLTokenSequence(seqCollection)
  }

  private init(type: DateTimeType, precision: Int?, withTimeZone: Bool?) {
    self.type = type
    self.precision = precision
    self.withTimeZone = withTimeZone
  }

  /// Create "TIMESTAMP" type.
  public static func timestamp(
    precision: Int? = nil,
    withTimeZone: Bool? = nil
  ) -> ConstantDateTimeTypeName {
    return ConstantDateTimeTypeName(
      type: .timestamp,
      precision: precision,
      withTimeZone: withTimeZone
    )
  }

  /// Create "TIMESTAMP" type without any options.
  public static let timestamp: ConstantDateTimeTypeName = .timestamp()

  /// Create "TIME" type.
  public static func time(
    precision: Int? = nil,
    withTimeZone: Bool? = nil
  ) -> ConstantDateTimeTypeName {
    return ConstantDateTimeTypeName(
      type: .time,
      precision: precision,
      withTimeZone: withTimeZone
    )
  }

  /// Create "TIME" type without any options.
  public static let time: ConstantDateTimeTypeName = .time()
}
