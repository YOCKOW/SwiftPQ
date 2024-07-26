/* *************************************************************************************************
 AttributeList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing an attribute name which is described as `attr_name` in "gram.y".
public enum AttributeName: NameRepresentation {
  case columnLabel(ColumnLabel)

  public init(_ label: ColumnLabel) {
    self = .columnLabel(label)
  }

  public struct Tokens: Sequence {
    public struct Iterator: IteratorProtocol {
      public typealias Element = SQLToken
      private let _iterator: AnyTokenSequenceIterator
      fileprivate init(_ iterator: AnyTokenSequenceIterator) { self._iterator = iterator }
      public func next() -> Element? { return _iterator.next() }
    }
    private let _name: AttributeName
    fileprivate init(_ name: AttributeName) { self._name = name }
    public func makeIterator() -> Iterator {
      switch _name {
      case .columnLabel(let columnLabel):
        return .init(columnLabel.token.asSequence._anyIterator)
      }
    }
  }

  public var tokens: Tokens {
    return Tokens(self)
  }
}
internal protocol _AttributeNameConvertible {
  var _attributeName: AttributeName { get }
}
extension ColumnLabel: _AttributeNameConvertible {
  @inlinable
  var _attributeName: AttributeName { .init(self) }
}

/// A type representing attributes which is expressed as `attrs` in "gram.y".
public struct AttributeList: TokenSequenceGenerator {  
  public var names: NonEmptyList<AttributeName>

  public init(names: NonEmptyList<AttributeName>) {
    self.names = names
  }

  internal init(names: NonEmptyList<any _AttributeNameConvertible>) {
    self.init(names: names.map(\._attributeName))
  }

  public init(names: NonEmptyList<ColumnLabel>) {
    self.init(names: names.map({ $0 as any _AttributeNameConvertible }))
  }

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(
      dotJoiner,
      JoinedSQLTokenSequence(names, separator: dotJoiner)
    )
  }
}

extension AttributeList: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = AttributeName

  public init(arrayLiteral elements: AttributeName...) {
    guard let list = NonEmptyList<AttributeName>(items: elements) else {
      fatalError("List must not be empty.")
    }
    self.init(names: list)
  }
}
