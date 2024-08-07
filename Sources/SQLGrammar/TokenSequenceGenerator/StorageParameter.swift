/* *************************************************************************************************
 StorageParameter.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */


/// A pair of a key and an optional value. This is `reloption_elem` in "gram.y".
///
/// Reference: "[Storage Parameters](https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-STORAGE-PARAMETERS)".
public struct StorageParameter: TokenSequenceGenerator {
  public struct Key: TokenSequenceGenerator {
    /// Labels of which the name consists.
    public let labels: NonEmptyList<ColumnLabel>

    public var tokens: JoinedTokenSequence {
      return labels.joined(separator: dotJoiner)
    }

    public init(_ prefixLabel: ColumnLabel?, _ parameterName: ColumnLabel) {
      if let prefixLabel {
        self.labels = [prefixLabel, parameterName]
      } else {
        self.labels = [parameterName]
      }
    }

    public init(_ parameterName: ColumnLabel) {
      self.init(nil, parameterName)
    }

    public static let fillfactor: Key = .init("fillfactor")

    public static let oids: Key = .init("OIDS")

    public static let parallelWorkers: Key = .init("parallel_workers")

    public static let userCatalogTable: Key = .init("user_catalog_table")

    // TODO: Add more static constants
  }

  public struct Value: TokenSequenceGenerator {
    public let value: DefinitionArgument

    public typealias Tokens = DefinitionArgument.Tokens

    public var tokens: Tokens {
      return value.tokens
    }

    public init(_ value: DefinitionArgument) {
      self.value = value
    }
  }

  public let key: Key

  public let value: Value?

  public var tokens: JoinedTokenSequence {
    return .compacting(key, value, separator: SingleToken(Token.Operator.equalTo))
  }

  public init(key: Key, value: Value? = nil) {
    self.key = key
    self.value = value
  }
}

extension StorageParameter.Value: ExpressibleByBooleanLiteral,
                                  ExpressibleByFloatLiteral,
                                  ExpressibleByIntegerLiteral,
                                  ExpressibleByStringLiteral {
  public typealias BooleanLiteralType = DefinitionArgument.BooleanLiteralType
  public typealias FloatLiteralType = DefinitionArgument.FloatLiteralType
  public typealias IntegerLiteralType = DefinitionArgument.IntegerLiteralType
  public typealias StringLiteralType = DefinitionArgument.StringLiteralType

  @inlinable
  public init(booleanLiteral value: BooleanLiteralType) {
    self.init(DefinitionArgument(booleanLiteral: value))
  }

  @inlinable
  public init(floatLiteral value: FloatLiteralType) {
    self.init(DefinitionArgument(floatLiteral: value))
  }

  @inlinable
  public init(integerLiteral value: IntegerLiteralType) {
    self.init(DefinitionArgument(integerLiteral: value))
  }

  @inlinable
  public init(stringLiteral value: StringLiteralType) {
    self.init(DefinitionArgument(stringLiteral: value))
  }
}

/// A list of `StorageParameter`. This is described as `reloption_list` in "gram.y".
public struct StorageParameterList: TokenSequenceGenerator,
                                    InitializableWithNonEmptyList,
                                    ExpressibleByArrayLiteral,
                                    ExpressibleByDictionaryLiteral {
  public typealias NonEmptyListElement = StorageParameter
  public typealias ArrayLiteralElement = StorageParameter
  public typealias Key = StorageParameter.Key
  public typealias Value = StorageParameter.Value?

  public var parameters: NonEmptyList<StorageParameter>

  public var tokens: JoinedTokenSequence {
    return parameters.joinedByCommas()
  }

  public init(_ parameters: NonEmptyList<StorageParameter>) {
    self.parameters = parameters
  }

  public init(dictionaryLiteral elements: (StorageParameter.Key, StorageParameter.Value?)...) {
    guard let list = NonEmptyList<StorageParameter>(
      items: elements.map({ StorageParameter(key: $0.0, value: $0.1) })
    ) else {
      fatalError("Empty list not allowed.")
    }
    self.init(list)
  }
}

/// `reloptions` in "gram.y".
internal struct _StorageParameters: TokenSequenceGenerator {
  let list: StorageParameterList
  var tokens: Parenthesized<StorageParameterList> {
    return list.parenthesized
  }
  init(_ list: StorageParameterList) {
    self.list = list
  }
}
