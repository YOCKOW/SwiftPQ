/* *************************************************************************************************
 SQLTokenSequence+KeywordName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// TODO: Use macros?

private struct _KeywordNameBase {
  var schema: String?

  enum _Name {
    case token(SQLToken.Keyword)
    case string(String)

    var stringValue: String {
      get {
        switch self {
        case .token(let keyword):
          return keyword.description
        case .string(let string):
          return string
        }
      }
      set {
        self = .string(newValue)
      }
    }
  }

  private var _name: _Name

  var name: String {
    get {
      _name.stringValue
    }
    set {
      _name.stringValue = newValue
    }
  }

  var tokens: [SQLToken] {
    var tokens: [SQLToken] = []
    if let schema {
      tokens.append(contentsOf: [.identifier(schema), .joiner, .dot, .joiner])
    }
    switch _name {
    case .token(let keyword):
      tokens.append(keyword)
    case .string(let string):
      tokens.append(.identifier(string))
    }
    return tokens
  }

  init(schema: String? = nil, name: SQLToken) {
    guard case let keyword as SQLToken.Keyword = name else {
      fatalError("Not an instance of `SQLToken.Keyword`?!")
    }
    self.schema = schema
    self._name = .token(keyword)
  }

  init(schema: String? = nil, name: String) {
    self.schema = schema
    self._name = .string(name)
  }
}

/// A type that represents a name of function.
public struct FunctionName: SQLTokenSequence {
  private var _base: _KeywordNameBase

  /// A name of schema.
  public var schema: String? {
    get {
      _base.schema
    }
    set {
      _base.schema = newValue
    }
  }

  /// A name of the function.
  public var name: String {
    get {
      _base.name
    }
    set {
      _base.name = newValue
    }
  }

  public var tokens: [SQLToken] {
    _base.tokens
  }

  internal init(schema: String? = nil, name: SQLToken) {
    self._base = .init(schema: schema, name: name)
  }

  public init(schema: String? = nil, name: String) {
    self._base = .init(schema: schema, name: name)
  }
}

public struct AggregateName: SQLTokenSequence {
  private var _base: _KeywordNameBase

  /// A name of schema.
  public var schema: String? {
    get {
      _base.schema
    }
    set {
      _base.schema = newValue
    }
  }

  /// A name of the aggregation.
  public var name: String {
    get {
      _base.name
    }
    set {
      _base.name = newValue
    }
  }

  public var tokens: [SQLToken] {
    _base.tokens
  }

  internal init(schema: String? = nil, name: SQLToken) {
    self._base = .init(schema: schema, name: name)
  }

  public init(schema: String? = nil, name: String) {
    self._base = .init(schema: schema, name: name)
  }

  /// `ARRAY_AGG`
  public static let arrayAggregate: AggregateName = .init(name: .arrayAgg)

  /// `PERCENTILE_CONT`
  public static let continuousPercentile: AggregateName = .init(name: .percentileCont)

  /// `COUNT`
  public static let count: AggregateName = .init(name: .count)

  /// `STRING_AGG`
  public static let stringAggregate: AggregateName = .init(name: .stringAgg)

  /// `XMLAGG`
  public static let xmlAggregate: AggregateName = .init(name: .xmlagg)
}
