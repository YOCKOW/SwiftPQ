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
public struct TypeName: NameRepresentation,
                        _PossiblyQualifiedNameConvertible,
                        _PossiblyFunctionNameWithModifiersConvertible {
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

  internal var _qualifiedName: (some QualifiedName)? {
    struct __QualifiedName: QualifiedName {
      let identifier: ColumnIdentifier
      let indirection: Indirection?
      init(_ qualifiedName: any QualifiedName) {
        self.identifier = qualifiedName.identifier
        self.indirection = qualifiedName.indirection
      }
    }
    guard !isSet,
          arrayModifier == nil,
          case let sourceName as any _PossiblyQualifiedNameConvertible = name else {
      return Optional<__QualifiedName>.none
    }
    return sourceName._qualifiedName.map(__QualifiedName.init)
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    guard !isSet,
          arrayModifier == nil,
          case let sourceName as any _PossiblyFunctionNameWithModifiersConvertible = name else {
      return nil
    }
    return sourceName._functionNameWithModifiers
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

  public static let date: TypeName = GenericTypeName.date.typeName

  public static let json: TypeName = GenericTypeName.json.typeName

  public static let text: TypeName = GenericTypeName.text.typeName

  public static let interval: TypeName = ConstantIntervalTypeName().typeName
}

extension SimpleTypeName {
  /// Returns an instance of `TypeName` created from the name.
  public var typeName: TypeName {
    return TypeName(self)
  }
}

/// A representation of generic type name that corresponds to `GenericType` in "gram.y".
public struct GenericTypeName: SimpleTypeName,
                               _PossiblyQualifiedNameConvertible,
                               _PossiblyFunctionNameWithModifiersConvertible {
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

  private var __qualifiedName: (some QualifiedName)? {
    struct __QualifiedName: QualifiedName {
      let identifier: ColumnIdentifier
      let indirection: Indirection?
    }
    guard let colId = ColumnIdentifier(name) else {
      return Optional<__QualifiedName>.none
    }
    let indirection: Indirection? = attributes.map { (attrList) -> Indirection in
      return Indirection(Indirection.List(attrList.names.map({ .attributeName($0) })))
    }
    return __QualifiedName(identifier: colId, indirection: indirection)
  }

  internal var _qualifiedName: (some QualifiedName)? {
    return modifiers == nil ? __qualifiedName : nil
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    guard let qualifiedName = self.__qualifiedName else {
      return nil
    }
    let funcName = FunctionName(qualifiedName)
    let funcArgList: FunctionArgumentList? = modifiers.map {
      FunctionArgumentList($0.expressions.map({ $0.asFunctionArgument }))
    }
    return (funcName, funcArgList)
  }

  public static let date: GenericTypeName = .init("DATE")

  public static let json: GenericTypeName = .init(.json)!

  public static let text: GenericTypeName = .init(.text)!
}

/// A type representing a name of numeric.
public enum NumericTypeName: SimpleTypeName,
                             ConstantTypeName,
                             _PossiblyQualifiedNameConvertible,
                             _PossiblyFunctionNameWithModifiersConvertible {
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

  private func __qualifiedName(from token: SQLToken) -> AnyQualifiedName? {
    guard let colId = ColumnIdentifier(token) else { return nil }
    return AnyQualifiedName(identifier: colId, indirection: nil)
  }

  internal var _qualifiedName: AnyQualifiedName? {
    switch self {
    case .int:
      return __qualifiedName(from: .int)
    case .integer:
      return __qualifiedName(from: .integer)
    case .samllInt:
      return __qualifiedName(from: .smallint)
    case .bigInt:
      return __qualifiedName(from: .bigint)
    case .real:
      return __qualifiedName(from: .real)
    case .float(let precision):
      if precision != nil {
        return nil
      }
      return __qualifiedName(from: .float)
    case .doublePrecision:
      return nil
    case .decimal(let modifiers):
      if modifiers != nil {
        return nil
      }
      return __qualifiedName(from: .decimal)
    case .dec(let modifiers):
      if modifiers != nil {
        return nil
      }
      return __qualifiedName(from: .dec)
    case .numeric(let modifiers):
      if modifiers != nil {
        return nil
      }
      return __qualifiedName(from: .numeric)
    case .boolean:
      return __qualifiedName(from: .boolean)
    }
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    switch self {
    case .int:
      return __qualifiedName(from: .int).map({ (FunctionName($0), nil) })
    case .integer:
      return __qualifiedName(from: .integer).map({ (FunctionName($0), nil) })
    case .samllInt:
      return __qualifiedName(from: .smallint).map({ (FunctionName($0), nil) })
    case .bigInt:
      return __qualifiedName(from: .bigint).map({ (FunctionName($0), nil) })
    case .real:
      return __qualifiedName(from: .real).map({ (FunctionName($0), nil) })
    case .float(let precision):
      return __qualifiedName(from: .float).map {
        let funcName = FunctionName($0)
        let funcArgList: FunctionArgumentList? = precision.map {
          FunctionArgumentList(NonEmptyList(item: $0.asFunctionArgument))
        }
        return (funcName, funcArgList)
      }
    case .doublePrecision:
      return nil
    case .decimal(let modifiers):
      return __qualifiedName(from: .decimal).map {
        let funcName = FunctionName($0)
        let funcArgList: FunctionArgumentList? = modifiers.map(FunctionArgumentList.init)
        return (funcName, funcArgList)
      }
    case .dec(let modifiers):
      return __qualifiedName(from: .dec).map {
        let funcName = FunctionName($0)
        let funcArgList: FunctionArgumentList? = modifiers.map(FunctionArgumentList.init)
        return (funcName, funcArgList)
      }
    case .numeric(let modifiers):
      return __qualifiedName(from: .numeric).map {
        let funcName = FunctionName($0)
        let funcArgList: FunctionArgumentList? = modifiers.map(FunctionArgumentList.init)
        return (funcName, funcArgList)
      }
    case .boolean:
      return __qualifiedName(from: .boolean).map({ (FunctionName($0), nil) })
    }
  }
}

/// A name of bit string type, that is described as `Bit` in "gram.y".
public enum BitStringTypeName: SimpleTypeName,
                               _PossiblyQualifiedNameConvertible,
                               _PossiblyFunctionNameWithModifiersConvertible {
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


  internal var _qualifiedName: Optional<some QualifiedName> {
    struct __QualifiedName: QualifiedName {
      let identifier: ColumnIdentifier
      let indirection: Indirection?
    }
    var none: Optional<__QualifiedName> { .none }
    switch self {
    case .fixed(let length):
      if length != nil {
        return none
      }
      return ColumnIdentifier(.bit).map({ __QualifiedName(identifier: $0, indirection: nil) })
    case .varying:
      return none
    }
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    switch self {
    case .fixed(let length):
      guard let funcName = FunctionName(.bit) else { return nil }
      let funcArgList = length.map(FunctionArgumentList.init)
      return (funcName, funcArgList)
    case .varying:
      return nil
    }
  }
}

/// A name of constant character, that is described as `Character` in "gram.y".
public struct CharacterTypeName: SimpleTypeName,
                                 _PossiblyQualifiedNameConvertible,
                                 _PossiblyFunctionNameWithModifiersConvertible {
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

    fileprivate var _qualifiedName: AnyQualifiedName? {
      func __name(from token: SQLToken) -> AnyQualifiedName? {
        return ColumnIdentifier(token).map({ AnyQualifiedName(identifier: $0, indirection: nil) })
      }
      switch self {
      case .character:
        return __name(from: .character)
      case .char:
        return __name(from: .char)
      case .varchar:
        return __name(from: .varchar)
      case .nationalCharacter:
        return nil
      case .nationalChar:
        return nil
      case .nchar:
        return __name(from: .nchar)
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

  internal var _qualifiedName: AnyQualifiedName? {
    if varying || length != nil {
      return nil
    }
    return type._qualifiedName
  }
  
  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    if varying {
      return nil
    }
    guard let funcName = type._qualifiedName.flatMap(FunctionName.init) else { return nil }
    let funcArgList = length.map({ FunctionArgumentList([$0.asFunctionArgument]) })
    return (funcName, funcArgList)
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
public struct ConstantDateTimeTypeName: SimpleTypeName,
                                        ConstantTypeName,
                                        _PossiblyQualifiedNameConvertible,
                                        _PossiblyFunctionNameWithModifiersConvertible {
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

  internal var _qualifiedName: (some QualifiedName)? {
    struct __QualifiedName: QualifiedName {
      let identifier: ColumnIdentifier
      let indirection: Indirection?
    }
    var none: __QualifiedName? { .none }
    if precision != nil || withTimeZone != nil {
      return none
    }
    return ColumnIdentifier(type.token).map({ __QualifiedName(identifier: $0, indirection: nil) })
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    if withTimeZone != nil {
      return nil
    }
    guard let funcName = ColumnIdentifier(type.token).map({
      AnyQualifiedName(identifier: $0, indirection: nil)
    }).map({
      FunctionName($0)
    }) else {
      return nil
    }
    let funcArgList = precision.map({ FunctionArgumentList([$0.asFunctionArgument]) })
    return (funcName, funcArgList)
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
public struct ConstantIntervalTypeName: SimpleTypeName,
                                        _PossiblyQualifiedNameConvertible,
                                        _PossiblyFunctionNameWithModifiersConvertible {
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

  internal var _qualifiedName: (some QualifiedName)? {
    struct __QualifiedName: QualifiedName {
      let identifier: ColumnIdentifier
      let indirection: Indirection?
    }
    if option != nil {
      return Optional<__QualifiedName>.none
    }
    return ColumnIdentifier(.interval).map({ __QualifiedName(identifier: $0, indirection: nil) })
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    var funcName: FunctionName? {
      ColumnIdentifier(.interval).map({
        AnyQualifiedName(identifier: $0)
      }).map({
        FunctionName($0)
      })
    }
    switch option {
    case .fields:
      return nil
    case .precision(let precision):
      return funcName.map { ($0, FunctionArgumentList([precision.asFunctionArgument])) }
    case nil:
      return funcName.map { ($0, nil) }
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
public struct ConstantBitStringTypeName: ConstantTypeName,
                                         _PossiblyQualifiedNameConvertible,
                                         _PossiblyFunctionNameWithModifiersConvertible {
  public let name: BitStringTypeName

  public var tokens: BitStringTypeName.Tokens {
    return name.tokens
  }

  internal var _qualifiedName: (some QualifiedName)? {
    return name._qualifiedName
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    return name._functionNameWithModifiers
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
public struct ConstantCharacterTypeName: ConstantTypeName,
                                         _PossiblyQualifiedNameConvertible,
                                         _PossiblyFunctionNameWithModifiersConvertible {
  public typealias CharacterType = CharacterTypeName.CharacterType

  /// Base name.
  public let name: CharacterTypeName

  public var tokens: CharacterTypeName.Tokens {
    return name.tokens
  }

  internal var _qualifiedName: (some QualifiedName)? {
    return name._qualifiedName
  }

  internal var _functionNameWithModifiers: (FunctionName, FunctionArgumentList?)? {
    return name._functionNameWithModifiers
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

