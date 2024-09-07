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
  public typealias SubSequence = Self

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

  fileprivate let _data: _Data

  public var data: Data {
    switch _data {
    case .pointer(let pointer, let length):
      return Data(UnsafeRawBufferPointer(start: pointer, count: length))
    case .data(let data):
      return data
    }
  }

  internal init(pointer: UnsafePointer<UInt8>, length: Int) {
    self._data = .pointer(pointer, length: length)
  }

  internal init<T>(copyingBytes pointer: UnsafePointer<T>) {
    let p = UnsafeRawBufferPointer(start: UnsafeRawPointer(pointer), count: MemoryLayout<T>.size)
    self._data = .data(Data(p))
  }

  public init(data: Data) {
    self._data = .data(data)
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = UInt8

    private let _data: _Data
    private var _currentOffset: Int

    public mutating func next() -> Element? {
      guard _currentOffset < _data.count else { return nil }
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

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    return .init(i._offset + distance)
  }

  public var count: Int {
    return _data.count
  }

  public subscript(position: Index) -> UInt8 {
    return _data[position._offset]
  }

  public subscript(bounds: Range<Index>) -> BinaryRepresentation {
    switch _data {
    case .pointer(let pointer, let length):
      precondition(
        (
          bounds.lowerBound._offset >= 0
          && bounds.upperBound._offset <= length
        ),
        "Out of bounds."
      )
      let newPointer = pointer.advanced(by: bounds.lowerBound._offset)
      let newLength = bounds.upperBound._offset - bounds.lowerBound._offset
      return BinaryRepresentation(pointer: newPointer, length: newLength)
    case .data(let data):
      let subdata = data[relativeBounds: bounds.lowerBound._offset..<bounds.upperBound._offset]
      return BinaryRepresentation(data: subdata)
    }
  }

  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    return try _data.withUnsafeBytes(body)
  }

  public var regions: Regions {
    return .init(self)
  }
}

extension BinaryRepresentation: Equatable {
  private func _isEqual<D>(to data: D) -> Bool where D: DataProtocol {
    guard self.count == data.count else {
      return false
    }
    var myIndex = self.startIndex
    var dataIndex = data.startIndex
    while myIndex < self.endIndex && dataIndex < data.endIndex {
      guard self[myIndex] == data[dataIndex] else {
        return false
      }
      myIndex = self.index(after: myIndex)
      dataIndex = data.index(after: dataIndex)
    }
    return true
  }

  public static func == <D>(lhs: BinaryRepresentation, rhs: D) -> Bool where D: DataProtocol {
    return lhs._isEqual(to: rhs)
  }

  public static func ==(lhs: BinaryRepresentation, rhs: BinaryRepresentation) -> Bool {
    return lhs._isEqual(to: rhs)
  }
}

extension BinaryRepresentation {
  public static func +(lhs: BinaryRepresentation, rhs: BinaryRepresentation) -> BinaryRepresentation {
    return BinaryRepresentation(data: lhs.data + rhs.data)
  }
}

extension BinaryRepresentation: CustomDebugStringConvertible {
  public var debugDescription: String {
    var desc = "BinaryRepresentation(\(count) bytes):\n"
    let MAX = 256
    let nn = Swift.min(count, MAX)
    for ii in 0..<nn {
      let byte = self[relativeIndex: ii]
      if byte < 0x10 {
        desc += "0"
      }
      desc += String(byte, radix: 16, uppercase: true)
      if ii % 8 == 7 {
        desc += "\n"
      } else if ii < nn - 1 {
        desc += " "
      }
    }
    if count > MAX {
      desc += "…"
    }
    return desc
  }
}

extension Data {
  public init(_ binaryRepresentation: BinaryRepresentation) {
    switch binaryRepresentation._data {
    case .pointer(let pointer, length: let length):
      self.init(bytes: pointer, count: length)
    case .data(let data):
      self = data
    }
  }
}
