/* *************************************************************************************************
 AttributeName.swift
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

  public final class Iterator: IteratorProtocol {
    public typealias Element = SQLToken

    private let _iterator: AnySQLTokenSequenceIterator

    fileprivate init(_ iterator: AnySQLTokenSequenceIterator) {
      self._iterator = iterator
    }

    public func next() -> Element? {
      return _iterator.next()
    }
  }

  public func makeIterator() -> Iterator {
    switch self {
    case .columnLabel(let columnLabel):
      return .init(AnySQLTokenSequenceIterator(columnLabel.token.asSequence))
    }
  }
}

internal protocol _AttributeNameConvertible {
  var _attributeName: AttributeName { get }
}
extension ColumnLabel: _AttributeNameConvertible {
  @inlinable
  var _attributeName: AttributeName { .init(self) }
}
