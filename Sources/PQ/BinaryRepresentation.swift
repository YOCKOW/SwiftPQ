/* *************************************************************************************************
 BinaryRepresentation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

/// Binary representation supposed to be used as an execution parameter or as a query result value.
///
/// - Warning: Binary data may hold a memory area associated with `PGresult` when it is returned as
///            a query result value. That means that `EXC_BAD_ACCESS` may occur after the result is
///            cleared.
public struct BinaryRepresentation: Sequence,
                                    Collection,
                                    BidirectionalCollection,
                                    ContiguousBytes,
                                    DataProtocol {
  public typealias Element = UInt8
  public typealias Regions = CollectionOfOne<Self>

  fileprivate enum _Data {
    case pointer(UnsafePointer<UInt8>, length: Int)
    case data(Data)

    subscript(_ offset: Int) -> UInt8 {
      switch self {
      case .pointer(let pointer, let length):
        guard offset < length else {
          fatalError("Out of bounds.")
        }
        return pointer.advanced(by: offset).pointee
      case .data(let data):
        return data[relativeIndex: offset]
      }
    }

    var count: Int {
      switch self {
      case .pointer(_, let length):
        return length
      case .data(let data):
        return data.count
      }
    }

    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
      switch self {
      case .pointer(let pointer, let length):
        return try body(UnsafeRawBufferPointer(start: UnsafeRawPointer(pointer), count: length))
      case .data(let data):
        return try data.withUnsafeBytes(body)
      }
    }
  }

  private let _data: _Data

  internal init(pointer: UnsafePointer<UInt8>, length: Int) {
    self._data = .pointer(pointer, length: length)
  }

  public init(data: Data) {
    self._data = .data(data)
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = UInt8

    private let _data: _Data
    private var _currentOffset: Int

    public mutating func next() -> Element? {
      guard _data.count < _currentOffset else { return nil }
      let byte = _data[_currentOffset]
      _currentOffset += 1
      return byte
    }

    fileprivate init(data: _Data) {
      self._data = data
      self._currentOffset = 0
    }
  }

  public func makeIterator() -> Iterator {
    return .init(data: _data)
  }


  public struct Index: Comparable {
    fileprivate let _offset: Int
    fileprivate init(_ offset: Int) {
      self._offset = offset
    }

    public static func < (lhs: Index, rhs: Index) -> Bool {
      return lhs._offset < rhs._offset
    }
  }

  public var startIndex: Index {
    return .init(0)
  }

  public var endIndex: Index {
    return .init(_data.count)
  }

  public func index(after i: Index) -> Index {
    return .init(i._offset + 1)
  }

  public func index(before i: Index) -> Index {
    return .init(i._offset - 1)
  }

  public subscript(position: Index) -> UInt8 {
    return _data[position._offset]
  }

  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    return try _data.withUnsafeBytes(body)
  }

  public var regions: Regions {
    return .init(self)
  }
}
