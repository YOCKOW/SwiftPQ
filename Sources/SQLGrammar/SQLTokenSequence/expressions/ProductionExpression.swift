/* *************************************************************************************************
 ProductionExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A reference to a column.
public struct ColumnReference: ProductionExpression,
                               ValueExpression,
                               QualifiedName,
                               ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public let tableName: TableName?

  public let columnName: String

  /// Additional elements of indirection.
  ///
  /// This property can make an instance compatible with PostgreSQL's parser
  /// because `columnref` is defined as `ColId | ColId indirection` in "gram.y".
  public var trailingIndirection: Indirection? = nil

  public var identifier: ColumnIdentifier {
    return tableName?.identifier ?? ColumnIdentifier(columnName)
  }

  public var indirection: Indirection? {
    guard let tableName else { return nil }
    let colElem = Indirection.List.Element.attributeName(AttributeName(ColumnLabel(columnName)))
    if var indirection = tableName.indirection {
      indirection.list.append(colElem)
      if let trailingIndirection {
        indirection.list.append(contentsOf: trailingIndirection.list)
      }
      return indirection
    } else {
      var list = NonEmptyList<Indirection.List.Element>(item: colElem)
      if let trailingIndirection {
        list.append(contentsOf: trailingIndirection.list)
      }
      return Indirection(Indirection.List(list))
    }
  }

  public init(tableName: TableName? = nil, columnName: String) {
    self.tableName = tableName
    self.columnName = columnName
  }

  public init(stringLiteral value: String) {
    self.init(columnName: value)
  }
}

/// A type representing a constant as an expression.
/// It is described as `AexprConst` in "gram.y".
public protocol ConstantExpression: ProductionExpression {}

/// A type of constant expression that contains only one token.
public protocol SingleTokenConstantExpression: ConstantExpression
where Tokens == Array<Element>,
      Iterator == SingleTokenIterator<Element> {
  var token: Element { get }
  init?(_ token: SQLToken)
}

extension SingleTokenConstantExpression {
  public var tokens: Tokens {
    return [self.token]
  }

  public func makeIterator() -> Iterator {
    return .init(self.token)
  }
}

/// Unsigned integer constant representation, which is described as `Iconst` (`ICONST`) in "gram.y".
public struct UnsignedIntegerConstantExpression: SingleTokenConstantExpression,
                                                 ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = UInt64

  public typealias Element = SQLToken.NumericConstant

  public let token: SQLToken.NumericConstant

  public init?(_ token: SQLToken) {
    guard
      case let numericConstantToken as SQLToken.NumericConstant = token,
      numericConstantToken.isInteger, !numericConstantToken.isNegative
    else {
      return nil
    }
    self.token = numericConstantToken
  }

  public init<T>(_ uint: T) where T: UnsignedInteger & SQLIntegerType {
    self.token = SQLToken.NumericConstant(uint)
  }

  public init(integerLiteral value: UInt64) {
    self.init(value)
  }
}

/// Unsigned float constant representation, which is described as `FCONST` in "gram.y".
public struct UnsignedFloatConstantExpression: SingleTokenConstantExpression {
  public typealias FloatLiteralType = Double
  public typealias Element = SQLToken.NumericConstant

  public let token: SQLToken.NumericConstant

  public init?(_ token: SQLToken) {
    guard
      case let numericConstantToken as SQLToken.NumericConstant = token,
      numericConstantToken.isFloat, !numericConstantToken.isNegative
    else {
      return nil
    }
    self.token = numericConstantToken
  }

  public init?<T>(_ float: T) where T: SQLFloatType {
    if float < 0 {
      return nil
    }
    self.token = SQLToken.NumericConstant(float)
  }
}

/// String constant representation, which is described as `Sconst` (`SCONST`) in "gram.y".
public struct StringConstantExpression: SingleTokenConstantExpression, ExpressibleByStringLiteral {
  public typealias StringLiteralType = String
  public typealias Element = SQLToken.StringConstant

  public let token: SQLToken.StringConstant

  public init?(_ token: SQLToken) {
    guard case let strToken as SQLToken.StringConstant = token else { return nil }
    self.token = strToken
  }

  public init<S>(_ string: S, encodingIsUTF8: Bool = true) where S: StringProtocol {
    self.token = SQLToken.StringConstant(rawValue: String(string), encodingIsUTF8: encodingIsUTF8)
  }

  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}


/// Bit-string constant representation, which is described as `BCONST` and `XCONST` in "gram.y".
public struct BitStringConstantExpression: SingleTokenConstantExpression {
  public typealias Element = SQLToken.BitStringConstant

  public let token: SQLToken.BitStringConstant
  
  public init?(_ token: SQLToken) {
    guard case let bToken as SQLToken.BitStringConstant = token else { return nil }
    self.token = bToken
  }
}