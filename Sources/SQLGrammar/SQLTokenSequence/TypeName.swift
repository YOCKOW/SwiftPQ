/* *************************************************************************************************
 TypeName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing `SimpleTypename` described in "gram.y".
public protocol SimpleTypeName: NameRepresentation {}

/// A type representing a name of constant type.
public protocol ConstantTypeName: NameRepresentation {}

/// A name of a type that corresponds to `Typename` in "gram.y"
public struct TypeName: NameRepresentation {
  public enum ArrayModifier: Segment {
    case oneDimensionalArray(size: UnsignedIntegerConstantExpression?)
    case multipleDimensionalArray(ArrayBoundList)

    public var tokens: JoinedSQLTokenSequence {
      switch self {
      case .oneDimensionalArray(let size):
        return .compacting(
          SingleToken(.array),
          SingleToken.joiner,
          LeftSquareBracket.leftSquareBracket,
          size,
          RightSquareBracket.rightSquareBracket
        )
      case .multipleDimensionalArray(let arrayBoundList):
        return arrayBoundList.tokens
      }
    }
  }

  /// A Boolean value that indicates whether or not the type name is a set
  /// which means multiple-row type.
  /// In short, `SETOF` modifier is added if this value is `true`.
  public let isSet: Bool

  /// The type name itself.
  public let name: any SimpleTypeName

  public let arrayModifier: ArrayModifier?

  public var tokens: JoinedSQLTokenSequence {
    var sequences: [any SQLTokenSequence] = []

    if isSet {
      sequences.append(SingleToken(.setof))
    }

    sequences.append(name)

    if let arrayModifier = self.arrayModifier {
      sequences.append(arrayModifier)
    }

    return JoinedSQLTokenSequence(sequences)
  }

  public init(_ name: any SimpleTypeName, arrayModifier: ArrayModifier? = nil, isSet: Bool = false) {
    self.name = name
    self.arrayModifier = arrayModifier
    self.isSet = isSet
  }

  /// Create a type name of array.
  public static func arrayOf(_ name: any SimpleTypeName, numberOfDimensions: Int = 1) -> TypeName {
    if numberOfDimensions < 0 {
      fatalError("Negative number of dimensions?!")
    }
    if numberOfDimensions == 0 {
      return TypeName(name)
    }
    return TypeName(
      name,
      arrayModifier: .multipleDimensionalArray(
        ArrayBoundList(
          NonEmptyList<UnsignedIntegerConstantExpression?>(
            items: (0..<numberOfDimensions).map { _ in nil }
          )!
        )
      )
    )
  }

  public static let int: TypeName = NumericTypeName.int.typeName

  public static let bigInt: TypeName = NumericTypeName.bigInt.typeName

  public static let float: TypeName = NumericTypeName.float.typeName

  public static let double: TypeName = NumericTypeName.double.typeName

  public static let boolean: TypeName = NumericTypeName.boolean.typeName

  public static let json: TypeName = GenericTypeName.json.typeName

  public static let text: TypeName = GenericTypeName.text.typeName
}

extension SimpleTypeName {
  /// Returns an instance of `TypeName` created from the name.
  public var typeName: TypeName {
    return TypeName(self)
  }
}

/// A representation of generic type name that corresponds to `GenericType` in "gram.y".
public struct GenericTypeName: SimpleTypeName {
  private let _name: TypeOrFunctionName

  public var name: SQLToken {
    return _name.token
  }

  public let attributes: AttributeList?

  public let modifiers: GeneralExpressionList?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      SingleToken(_name), attributes, modifiers?.parenthesized,
      separator: SingleToken.joiner
    )
  }

  internal init(
    _ name: TypeOrFunctionName,
    attributes: AttributeList?,
    modifiers: GeneralExpressionList?
  ) {
    self._name = name
    self.attributes = attributes
    self.modifiers = modifiers
  }

  /// Creates an instance. Returns `nil` if the given `name` is an invalid token.
  public init?(
    _ name: SQLToken,
    attributes: AttributeList? = nil,
    modifiers: GeneralExpressionList? = nil
  ) {
    guard let name = TypeOrFunctionName(name) else { return nil }
    self.init(name, attributes: attributes, modifiers: modifiers)
  }

  /// Creates an instance.
  public init(
    _ name: String,
    attributes: AttributeList? = nil,
    modifiers: GeneralExpressionList? = nil
  ) {
    self.init(SQLToken.identifier(name), attributes: attributes, modifiers: modifiers)!
  }

  public static let json: GenericTypeName = .init(.json)!

  public static let text: GenericTypeName = .init(.text)!
}

/// A type representing a name of numeric.
public enum NumericTypeName: SimpleTypeName, ConstantTypeName {
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
  case float(precision: UnsignedIntegerConstantExpression? = nil)

  /// `FLOAT` token without precision.
  public static let float: NumericTypeName = .float()

  /// `DOUBLE PRECISION` type.
  case doublePrecision

  public static let double: NumericTypeName = .doublePrecision

  /// `DECIMAL` type.
  case decimal(modifiers: GeneralExpressionList? = nil)

  /// `DECIMAL` type withoug modifiers.
  public static let decimal: NumericTypeName = .decimal()

  public static func decimal(precision: UnsignedIntegerConstantExpression) -> NumericTypeName {
    fatalError("Unimplemented.")
  }

  /// `DEC` type.
  case dec(modifiers: GeneralExpressionList? = nil)

  /// `DEC` type without modifiers.
  public static let dec: NumericTypeName = .dec()

  /// `NUMERIC` type.
  case numeric(modifiers: GeneralExpressionList? = nil)

  public static func numeric(
    precision: UnsignedIntegerConstantExpression,
    scale: UnsignedIntegerConstantExpression? = nil
  ) -> NumericTypeName {
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
        seqCollection.append(precision.parenthesized)
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

/// A name of bit string type, that is described as `Bit` in "gram.y".
public enum BitStringTypeName: SimpleTypeName {
  /// Fixed-length bit string
  case fixed(length: GeneralExpressionList? = nil)

  public static func fixed(length: UnsignedIntegerConstantExpression) -> BitStringTypeName {
    return .fixed(length: GeneralExpressionList([length]))
  }

  public static let fixed: BitStringTypeName = .fixed()

  /// Variable-length bit string
  case varying(length: GeneralExpressionList? = nil)

  public static func varying(length: UnsignedIntegerConstantExpression) -> BitStringTypeName {
    return .varying(length: GeneralExpressionList([length]))
  }

  public static let varying: BitStringTypeName = .varying()

  @inlinable
  public var tokens: JoinedSQLTokenSequence {
    var tokens: [any SQLTokenSequence] = [SingleToken(.bit)]

    func __append(length: GeneralExpressionList) {
      tokens.append(SingleToken.joiner)
      tokens.append(length.parenthesized)
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

/// A name of constant character, that is described as `Character` in "gram.y".
public struct CharacterTypeName: SimpleTypeName {
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

  private let length: UnsignedIntegerConstantExpression?

  public var tokens: JoinedSQLTokenSequence {
    var seqCollection: [any SQLTokenSequence] = [type]
    if varying {
      seqCollection.append(SingleToken(.varying))
    }
    if let length = self.length {
      seqCollection.append(SingleToken.joiner)
      seqCollection.append(length.parenthesized)
    }
    return JoinedSQLTokenSequence(seqCollection)
  }

  fileprivate init(type: CharacterType, varying: Bool, length: UnsignedIntegerConstantExpression?) {
    assert(!varying || type.canBeVarying, "'VARYING' is not available.")
    self.type = type
    self.varying = varying
    self.length = length
  }

  /// Create `CHARACTER` type.
  public static func character(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return CharacterTypeName(type: .character, varying: varying, length: length)
  }

  /// Create fixed-length `CHARACTER` type without specifying length.
  public static let character: CharacterTypeName = .character()

  /// Create `CHAR` type.
  public static func char(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return CharacterTypeName(type: .char, varying: varying, length: length)
  }

  /// Create fixed-length `CHAR` type without specifying length.
  public static let char: CharacterTypeName = .char()

  /// Create `VARCHAR` type.
  public static func varchar(length: UnsignedIntegerConstantExpression? = nil) -> CharacterTypeName {
    return CharacterTypeName(type: .varchar, varying: false, length: length)
  }

  /// Create fixed-length `VARCHAR` type without specifying length.
  public static let varchar: CharacterTypeName = .varchar()

  /// Create `NATIONAL CHARACTER` type.
  public static func nationalCharacter(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return CharacterTypeName(type: .nationalCharacter, varying: varying, length: length)
  }

  /// Create fixed-length `NATIONAL CHARACTER` type without specifying length.
  public static let nationalCharacter: CharacterTypeName = .nationalCharacter()

  /// Create `NATIONAL CHAR` type.
  public static func nationalChar(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return CharacterTypeName(type: .nationalChar, varying: varying, length: length)
  }

  /// Create fixed-length `NATIONAL CHAR` type without specifying length.
  public static let nationalChar: CharacterTypeName = .nationalChar()

  /// Create `NCHAR` type.
  public static func nchar(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return CharacterTypeName(type: .nchar, varying: varying, length: length)
  }

  /// Create fixed-length `NCHAR` type without specifying length.
  public static let nchar: CharacterTypeName = .nchar()
}

/// A name of date-time type, that is described as `ConstDatetime` in "gram.y".
public struct ConstantDateTimeTypeName: SimpleTypeName, ConstantTypeName {
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
  public let precision: UnsignedIntegerConstantExpression?

  public let withTimeZone: Bool?

  public var tokens: JoinedSQLTokenSequence {
    var seqCollection: [any SQLTokenSequence] = []
    if let precision {
      seqCollection.append(
        SingleToken(type.token).followedBy(parenthesized: precision)
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

  private init(type: DateTimeType, precision: UnsignedIntegerConstantExpression?, withTimeZone: Bool?) {
    self.type = type
    self.precision = precision
    self.withTimeZone = withTimeZone
  }

  /// Create "TIMESTAMP" type.
  public static func timestamp(
    precision: UnsignedIntegerConstantExpression? = nil,
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
    precision: UnsignedIntegerConstantExpression? = nil,
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

/// A type name that represents `ConstInterval opt_interval` or `ConstInterval '(' Iconst ')'`.
public struct ConstantIntervalTypeName: SimpleTypeName {
  public let option: IntervalOption?

  public var tokens: JoinedSQLTokenSequence {
    switch option {
    case .fields(let phrase):
      return JoinedSQLTokenSequence(SingleToken(.interval), phrase)
    case .precision(let p):
      return SingleToken(.interval).followedBy(parenthesized: p)
    case nil:
      return JoinedSQLTokenSequence(SingleToken(.interval))
    }
  }

  public init(option: IntervalOption? = nil) {
    self.option = option
  }

  public init(fields: IntervalFieldsPhrase) {
    self.option = .fields(fields)
  }

  public init(precision: UnsignedIntegerConstantExpression) {
    self.option = .precision(precision)
  }
}

/// A name of constant bit string type, that is described as `ConstBit` in "gram.y".
public struct ConstantBitStringTypeName: ConstantTypeName {
  public let name: BitStringTypeName

  public var tokens: BitStringTypeName.Tokens {
    return name.tokens
  }

  public init(_ name: BitStringTypeName) {
    self.name = name
  }

  /// Fixed-length bit string
  public static func fixed(length: GeneralExpressionList? = nil) -> ConstantBitStringTypeName {
    return .init(.fixed(length: length))
  }

  public static func fixed(length: UnsignedIntegerConstantExpression) -> ConstantBitStringTypeName {
    return .init(.fixed(length: length))
  }

  public static let fixed: ConstantBitStringTypeName = .fixed()

  /// Variable-length bit string
  public static func varying(length: GeneralExpressionList? = nil) -> ConstantBitStringTypeName {
    return .init(.varying(length: length))
  }

  public static func varying(length: UnsignedIntegerConstantExpression) -> ConstantBitStringTypeName {
    return .init(.varying(length: length))
  }

  public static let varying: ConstantBitStringTypeName = .varying()
}

/// A name of constant character, that is described as `ConstCharacter` in "gram.y".
public struct ConstantCharacterTypeName: ConstantTypeName {
  public typealias CharacterType = CharacterTypeName.CharacterType

  /// Base name.
  public let name: CharacterTypeName

  public var tokens: CharacterTypeName.Tokens {
    return name.tokens
  }

  public init(_ name: CharacterTypeName) {
    self.name = name
  }

  private init(type: CharacterType, varying: Bool, length: UnsignedIntegerConstantExpression?) {
    self.init(CharacterTypeName(type: type, varying: varying, length: length))
  }

  /// Create `CHARACTER` type.
  public static func character(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .character, varying: varying, length: length)
  }

  /// Create fixed-length `CHARACTER` type without specifying length.
  public static let character: ConstantCharacterTypeName = .character()

  /// Create `CHAR` type.
  public static func char(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .char, varying: varying, length: length)
  }

  /// Create fixed-length `CHAR` type without specifying length.
  public static let char: ConstantCharacterTypeName = .char()

  /// Create `VARCHAR` type.
  public static func varchar(length: UnsignedIntegerConstantExpression? = nil) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .varchar, varying: false, length: length)
  }

  /// Create fixed-length `VARCHAR` type without specifying length.
  public static let varchar: ConstantCharacterTypeName = .varchar()

  /// Create `NATIONAL CHARACTER` type.
  public static func nationalCharacter(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .nationalCharacter, varying: varying, length: length)
  }

  /// Create fixed-length `NATIONAL CHARACTER` type without specifying length.
  public static let nationalCharacter: ConstantCharacterTypeName = .nationalCharacter()

  /// Create `NATIONAL CHAR` type.
  public static func nationalChar(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> ConstantCharacterTypeName {
    return ConstantCharacterTypeName(type: .nationalChar, varying: varying, length: length)
  }

  /// Create fixed-length `NATIONAL CHAR` type without specifying length.
  public static let nationalChar: ConstantCharacterTypeName = .nationalChar()

  /// Create `NCHAR` type.
  public static func nchar(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
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

