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

    public var tokens: JoinedTokenSequence {
      switch self {
      case .oneDimensionalArray(let size):
        return .compacting(
          SingleToken.array,
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

  public var tokens: JoinedTokenSequence {
    var sequences: [any TokenSequenceGenerator] = []

    if isSet {
      sequences.append(SingleToken.setof)
    }

    sequences.append(name)

    if let arrayModifier = self.arrayModifier {
      sequences.append(arrayModifier)
    }

    return JoinedTokenSequence(sequences)
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

  @inlinable
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

  // `GenericTypeName`s

  public static let date: TypeName = GenericTypeName.date.typeName

  public static let json: TypeName = GenericTypeName.json.typeName

  public static let text: TypeName = GenericTypeName.text.typeName

  // `NumericTypeName`s

  public static let int: TypeName = NumericTypeName.int.typeName

  public static let integer: TypeName = NumericTypeName.integer.typeName

  public static let smallInt: TypeName = NumericTypeName.samllInt.typeName

  public static let bigInt: TypeName = NumericTypeName.bigInt.typeName

  public static let real: TypeName = NumericTypeName.real.typeName

  @inlinable
  public static func float(_ precision: UnsignedIntegerConstantExpression) -> TypeName {
    return NumericTypeName.float(precision: precision).typeName
  }

  public static let float: TypeName = NumericTypeName.float.typeName

  public static let doublePrecision: TypeName = NumericTypeName.doublePrecision.typeName

  public static let double: TypeName = NumericTypeName.double.typeName

  @inlinable
  public static func decimal(_ precision: UnsignedIntegerConstantExpression) -> TypeName {
    return NumericTypeName.decimal(precision: precision).typeName
  }

  public static let decimal: TypeName = NumericTypeName.decimal.typeName

  @inlinable
  public static func dec(_ precision: UnsignedIntegerConstantExpression) -> TypeName {
    return NumericTypeName.dec(precision: precision).typeName
  }

  public static let dec: TypeName = NumericTypeName.dec.typeName

  @inlinable
  public static func numeric<Scale>(
    _ precision: UnsignedIntegerConstantExpression,
    _ scale: Scale? = Optional<UnsignedIntegerConstantExpression>.none
  ) -> TypeName where Scale: SignedIntegerConstantExpression, Scale: GeneralExpression {
    return NumericTypeName.numeric(precision: precision, scale: scale).typeName
  }

  public static let numeric: TypeName = NumericTypeName.numeric.typeName

  public static let boolean: TypeName = NumericTypeName.boolean.typeName

  // `BitStringTypeName`s

  @inlinable
  public static func bit(_ length: UnsignedIntegerConstantExpression) -> TypeName {
    return BitStringTypeName.fixed(length: length).typeName
  }

  public static let bit: TypeName = BitStringTypeName.fixed.typeName

  @inlinable
  public static func bitVarying(_ length: UnsignedIntegerConstantExpression) -> TypeName {
    return BitStringTypeName.varying(length: length).typeName
  }

  public static let bitVarying: TypeName = BitStringTypeName.varying.typeName

  // `CharacterTypeName`s

  @inlinable
  public static func character(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression
  ) -> TypeName {
    return CharacterTypeName.character(varying: varying, length: length).typeName
  }

  @inlinable
  public static func character(
    _ length: UnsignedIntegerConstantExpression
  ) -> TypeName {
    return CharacterTypeName.character(varying: false, length: length).typeName
  }

  @inlinable
  public static func characterVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.characterVarying(length).typeName
  }

  public static let character: TypeName = CharacterTypeName.character.typeName

  @inlinable
  public static func char(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression
  ) -> TypeName {
    return CharacterTypeName.char(varying: varying, length: length).typeName
  }

  @inlinable
  public static func char(
    _ length: UnsignedIntegerConstantExpression
  ) -> TypeName {
    return CharacterTypeName.char(varying: false, length: length).typeName
  }

  @inlinable
  public static func charVarying(
    _ length: UnsignedIntegerConstantExpression
  ) -> TypeName {
    return CharacterTypeName.charVarying(length).typeName
  }

  public static let char: TypeName = CharacterTypeName.char.typeName

  @inlinable
  public static func varchar(_ length: UnsignedIntegerConstantExpression? = nil) -> TypeName {
    return CharacterTypeName.varchar(length).typeName
  }

  public static let varchar: TypeName = CharacterTypeName.varchar.typeName

  @inlinable
  public static func nationalCharacter(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.nationalCharacter(varying: varying, length: length).typeName
  }

  @inlinable
  public static func nationalCharacterVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.nationalCharacterVarying(length).typeName
  }

  public static let nationalCharacter: TypeName = CharacterTypeName.nationalCharacter.typeName

  @inlinable
  public static func nationalChar(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.nationalChar(varying: varying, length: length).typeName
  }

  @inlinable
  public static func nationalCharVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.nationalCharVarying(length).typeName
  }

  public static let nationalChar: TypeName = CharacterTypeName.nationalChar.typeName

  @inlinable
  public static func nchar(
    varying: Bool = false,
    length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.nchar(varying: varying, length: length).typeName
  }

  @inlinable
  public static func ncharVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> TypeName {
    return CharacterTypeName.ncharVarying(length).typeName
  }

  public static let nchar: TypeName = CharacterTypeName.nchar.typeName

  // `ConstantDateTimeTypeName`s

  @inlinable
  public static func timestamp(
    _ precision: UnsignedIntegerConstantExpression,
    withTimeZone: Bool? = nil
  ) -> TypeName {
    return ConstantDateTimeTypeName.timestamp(precision: precision, withTimeZone: withTimeZone).typeName
  }

  public static let timestamp: TypeName = ConstantDateTimeTypeName.timestamp.typeName


  @inlinable
  public static func time(
    _ precision: UnsignedIntegerConstantExpression,
    withTimeZone: Bool? = nil
  ) -> TypeName {
    return ConstantDateTimeTypeName.time(precision: precision, withTimeZone: withTimeZone).typeName
  }

  public static let time: TypeName = ConstantDateTimeTypeName.time.typeName

  // `ConstantIntervalTypeName`s

  @inlinable
  public static func interval(option: IntervalOption) -> TypeName {
    return ConstantIntervalTypeName(option: option).typeName
  }

  @inlinable
  public static func interval(_ fields: IntervalFieldsPhrase) -> TypeName {
    return ConstantIntervalTypeName(fields: fields).typeName
  }

  @inlinable
  public static func interval(_ precision: UnsignedIntegerConstantExpression) -> TypeName {
    return ConstantIntervalTypeName(precision: precision).typeName
  }

  public static let interval: TypeName = ConstantIntervalTypeName().typeName
}

extension SimpleTypeName {
  /// Returns an instance of `TypeName` created from the name.
  @inlinable
  public var typeName: TypeName {
    return TypeName(self)
  }
}

/// A representation of generic type name that corresponds to `GenericType` in "gram.y".
public struct GenericTypeName: SimpleTypeName,
                               _PossiblyQualifiedNameConvertible,
                               _PossiblyFunctionNameWithModifiersConvertible {
  private let _name: TypeOrFunctionName

  public var name: Token {
    return _name.token
  }

  public let attributes: AttributeList?

  public let modifiers: GeneralExpressionList?

  public var tokens: JoinedTokenSequence {
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
    _ name: Token,
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
    self.init(Token.identifier(name), attributes: attributes, modifiers: modifiers)!
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

  @inlinable
  public static func decimal(precision: UnsignedIntegerConstantExpression) -> NumericTypeName {
    return .decimal(modifiers: GeneralExpressionList(precision))
  }

  /// `DECIMAL` type withoug modifiers.
  public static let decimal: NumericTypeName = .decimal()

  /// `DEC` type.
  case dec(modifiers: GeneralExpressionList? = nil)

  @inlinable
  public static func dec(precision: UnsignedIntegerConstantExpression) -> NumericTypeName {
    return .dec(modifiers: GeneralExpressionList(precision))
  }

  /// `DEC` type without modifiers.
  public static let dec: NumericTypeName = .dec()

  /// `NUMERIC` type.
  case numeric(modifiers: GeneralExpressionList? = nil)

  /// `NUMERIC` type with precision and scale.
  @inlinable
  public static func numeric<Scale>(
    precision: UnsignedIntegerConstantExpression,
    scale: Scale? = Optional<UnsignedIntegerConstantExpression>.none
  ) -> NumericTypeName where Scale: SignedIntegerConstantExpression, Scale: GeneralExpression {
    guard let scale else {
      return .numeric(modifiers: GeneralExpressionList(precision))
    }
    return .numeric(modifiers: GeneralExpressionList(precision, scale))
  }

  /// `NUMERIC` type without modifiers.
  public static let numeric: NumericTypeName = .numeric(modifiers: nil)

  /// `BOOLEAN` type.
  case boolean

  @inlinable
  public var tokens: JoinedTokenSequence {
    switch self {
    case .int:
      return JoinedTokenSequence([SingleToken.int])
    case .integer:
      return JoinedTokenSequence([SingleToken.integer])
    case .samllInt:
      return JoinedTokenSequence([SingleToken.smallint])
    case .bigInt:
      return JoinedTokenSequence([SingleToken.bigint])
    case .real:
      return JoinedTokenSequence([SingleToken.real])
    case .float(let precision):
      var seqCollection: [any TokenSequenceGenerator] = [SingleToken.float]
      if let precision {
        seqCollection.append(SingleToken.joiner)
        seqCollection.append(precision.parenthesized)
      }
      return JoinedTokenSequence(seqCollection)
    case .doublePrecision:
      return JoinedTokenSequence(SingleToken.double, SingleToken.precision)
    case .decimal(let modifiers):
      var seqCollection: [any TokenSequenceGenerator] = [SingleToken.decimal]
      if let modifiers {
        seqCollection.append(SingleToken.joiner)
        seqCollection.append(modifiers.parenthesized)
      }
      return JoinedTokenSequence(seqCollection)
    case .dec(let modifiers):
      var seqCollection: [any TokenSequenceGenerator] = [SingleToken.dec]
      if let modifiers {
        seqCollection.append(SingleToken.joiner)
        seqCollection.append(modifiers.parenthesized)
      }
      return JoinedTokenSequence(seqCollection)
    case .numeric(let modifiers):
      var seqCollection: [any TokenSequenceGenerator] = [SingleToken.numeric]
      if let modifiers {
        seqCollection.append(SingleToken.joiner)
        seqCollection.append(modifiers.parenthesized)
      }
      return JoinedTokenSequence(seqCollection)
    case .boolean:
      return JoinedTokenSequence([SingleToken.boolean])
    }
  }

  private func __qualifiedName(from token: Token) -> AnyQualifiedName? {
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
  public var tokens: JoinedTokenSequence {
    var tokens: [any TokenSequenceGenerator] = [SingleToken.bit]

    func __append(length: GeneralExpressionList) {
      tokens.append(SingleToken.joiner)
      tokens.append(length.parenthesized)
    }

    switch self {
    case .fixed(let length):
      length.map(__append(length:))
    case .varying(let length):
      tokens.append(SingleToken.varying)
      length.map(__append(length:))
    }

    return JoinedTokenSequence(tokens)
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
      guard let funcName = FunctionName(Token.bit) else { return nil }
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
  public enum CharacterType: TokenSequenceGenerator {
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

    public var tokens: Array<Token> {
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
      func __name(from token: Token) -> AnyQualifiedName? {
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

  public var tokens: JoinedTokenSequence {
    var seqCollection: [any TokenSequenceGenerator] = [type]
    if varying {
      seqCollection.append(SingleToken.varying)
    }
    if let length = self.length {
      seqCollection.append(SingleToken.joiner)
      seqCollection.append(length.parenthesized)
    }
    return JoinedTokenSequence(seqCollection)
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

  /// Create `CHARACTER VARYING` type.
  public static func characterVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return .character(varying: true, length: length)
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

  /// Create `CHAR VARYING` type.
  public static func charVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return .char(varying: true, length: length)
  }

  /// Create fixed-length `CHAR` type without specifying length.
  public static let char: CharacterTypeName = .char()

  /// Create `VARCHAR` type.
  public static func varchar(_ length: UnsignedIntegerConstantExpression? = nil) -> CharacterTypeName {
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

  @inlinable
  public static func nationalCharacterVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return .nationalCharacter(varying: true, length: length)
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


  @inlinable
  public static func nationalCharVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return .nationalChar(varying: true, length: length)
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

  @inlinable
  public static func ncharVarying(
    _ length: UnsignedIntegerConstantExpression? = nil
  ) -> CharacterTypeName {
    return .nchar(varying: true, length: length)
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

    var token: Token {
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

  public var tokens: JoinedTokenSequence {
    var seqCollection: [any TokenSequenceGenerator] = []
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
    return JoinedTokenSequence(seqCollection)
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

  public var tokens: JoinedTokenSequence {
    switch option {
    case .fields(let phrase):
      return JoinedTokenSequence(SingleToken.interval, phrase)
    case .precision(let p):
      return SingleToken.interval.followedBy(parenthesized: p)
    case nil:
      return JoinedTokenSequence(SingleToken.interval)
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
  let tokens: [Token] = [.with, .time, .zone]
  static let withTimeZone: WithTimeZone = .init()
}

private final class WithoutTimeZone: Segment {
  let tokens: [Token] = [.without, .time, .zone]
  static let withoutTimeZone: WithoutTimeZone = .init()
}

