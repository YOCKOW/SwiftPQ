/* *************************************************************************************************
 QueryResult.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ
import Foundation
import SQLGrammar

/// An error corresponding to some of `ExecStatusType`.
public enum ExecutionError: Error {
  case emptyQuery
  case badResponse(message: String)
  case nonFatalError(message: String)
  case fatalError(message: String)
  case unexpectedError(message: String)

  /// Unimplemented yet...
  case unimplemented
}

private class _Cache<Key, Value> where Key: Hashable {
  private var _records: [Key: Value] = [:]
  func value(for key: Key, ifAbsent: () -> Value) -> Value {
    guard let value = _records[key] else {
      let newValue = ifAbsent()
      _records[key] = newValue
      return newValue
    }
    return value
  }
}

private final class _IndexedCache<Value>: _Cache<Int, Value> {
  func value(at index: Int, ifAbsent: () -> Value) -> Value {
    return super.value(for: index, ifAbsent: ifAbsent)
  }
}

public enum QueryResult: Equatable {
  public enum Format {
    case text
    case binary

    /// Unknown format.
    case unknown
  }

  /// A single field value of a row.
  public enum Value {
    case text(String)
    case binary(BinaryRepresentation)

    public init?<T>(_ value: T) where T: ValueConvertible {
      if let binary = value.sqlBinaryData {
        self = .binary(binary)
      } else if let string = value.sqlStringValue {
        self = .text(string)
      } else {
        return nil
      }
    }

    public func `as`<T>(_ type: T.Type) -> T? where T: ValueConvertible {
      switch self {
      case .text(let string):
        return T(sqlStringValue: string)
      case .binary(let data):
        return data.as(type)
      }
    }
  }

  /// A field value and its additional information.
  public struct Field {
    /// Object Identifier.
    public let oid: OID

    /// Column name.
    public let name: ColumnIdentifier

    /// Field value.
    public let value: QueryResult.Value?

    fileprivate init(oid: OID, name: ColumnIdentifier, value: QueryResult.Value?) {
      self.oid = oid
      self.name = name
      self.value = value
    }
  }

  /// Wrapper of a pointer to `PGresult`.
  fileprivate final class _PGResult: Equatable {
    private let _result: OpaquePointer

    static func == (lhs: _PGResult, rhs: _PGResult) -> Bool {
      return lhs._result == rhs._result
    }

    internal init(_ result: OpaquePointer) {
      self._result = result
    }

    deinit {
      PQclear(_result)
    }

    var numberOfRows: Int {
      return Int(PQntuples(_result))
    }

    var numberOfFields: Int {
      return Int(PQnfields(_result))
    }

    private let _columnNameCache: _IndexedCache<ColumnIdentifier> = .init()
    func columnName(at index: Int) -> ColumnIdentifier {
      assert(index >= 0 && index <= CInt.max, "Invalid index.")
      return _columnNameCache.value(at: index, ifAbsent: { 
        guard let cString = PQfname(_result, CInt(index)) else {
          fatalError("Out of range.")
        }
        return ColumnIdentifier(String(cString: cString))
      })
    }

    private let _columnIndexCache: _Cache<ColumnIdentifier, Int?> = .init()
    func columnIndex(for name: ColumnIdentifier) -> Int? {
      return _columnIndexCache.value(for: name, ifAbsent: {
        let result = PQfnumber(_result, name.token.description)
        if result < 0 {
          return nil
        }
        return Int(result)
      })
    }

    func tableOID(at index: Int) -> OID? {
      assert(index >= 0 && index <= CInt.max, "Invalid index.")
      let cOid = PQftable(_result, CInt(index))
      if cOid == CLibPQ.InvalidOid {
        return nil
      }
      return OID(rawValue: cOid)
    }

    func tableColumnNumer(at index: Int) -> Int {
      assert(index >= 0 && index <= CInt.max, "Invalid index.")
      return Int(PQftablecol(_result, CInt(index)))
    }

    func format(at index: Int) -> Format {
      assert(index >= 0 && index <= CInt.max, "Invalid index.")
      switch PQfformat(_result, CInt(index)) {
      case 0:
        return .text
      case 1:
        return .binary
      default:
        return .unknown
      }
    }

    func dataTypeOID(at index: Int) -> OID {
      assert(index >= 0 && index <= CInt.max, "Invalid index.")
      let cOid = PQftype(_result, CInt(index))
      return OID(rawValue: cOid)
    }

    /// The size of the server's internal representation of the data type.
    func allocatedDataSize(at index: Int) -> Int {
      assert(index >= 0 && index <= CInt.max, "Invalid index.")
      return Int(PQfsize(_result, CInt(index)))
    }

    func valueIsNull(at indices: (rowIndex: Int, columnIndex: Int)) -> Bool {
      assert(
        indices.rowIndex >= 0
        && indices.rowIndex <= CInt.max
        && indices.columnIndex >= 0
        && indices.columnIndex <= CInt.max,
        "Invalid index."
      )
      return PQgetisnull(_result, CInt(indices.rowIndex), CInt(indices.columnIndex)) == 1
    }

    func dataLength(at indices: (rowIndex: Int, columnIndex: Int)) -> Int {
      if valueIsNull(at: indices) {
        return 0
      }
      return Int(PQgetlength(_result, CInt(indices.rowIndex), CInt(indices.columnIndex)))
    }

    private let _valueCache: _IndexedCache<_IndexedCache<Value?>> = .init()
    func value(at indices: (rowIndex: Int, columnIndex: Int)) -> Value? {
      return _valueCache.value(at: indices.rowIndex, ifAbsent: {
        return _IndexedCache<Value?>()
      }).value(at: indices.columnIndex, ifAbsent: {
        if valueIsNull(at: indices) {
          return nil
        }
        guard let bytes = PQgetvalue(_result, CInt(indices.rowIndex), CInt(indices.columnIndex)) else {
          // unreachable?
          return nil
        }
        let format = format(at: indices.columnIndex)
        let length = dataLength(at: indices)
        switch format {
        case .text:
          guard let string = String(
            data: Data(UnsafeRawBufferPointer(start: bytes, count: length)),
            encoding: .utf8
          ) else {
            return nil
          }
          return .text(string)
        case .binary:
          let representation = BinaryRepresentation(
            pointer: bytes.withMemoryRebound(to: UInt8.self, capacity: length) { $0 },
            length: length
          )
          return .binary(representation)
        case .unknown:
          return nil // fatalError preferred?
        }
      })
    }
  }

  /// Representation of a row (a.k.a. "tuple").
  public final class Row: Equatable, BidirectionalCollection {
    public typealias Element = Field
    public typealias Index = Int

    private let _result: _PGResult

    /// An index of this row in the table.
    public let rowIndex: Int

    public static func == (lhs: Row, rhs: Row) -> Bool {
      return lhs._result == rhs._result && lhs.rowIndex == rhs.rowIndex
    }

    fileprivate init(_ result: _PGResult, rowIndex: Int) {
      self._result = result
      self.rowIndex = rowIndex
    }

    public let startIndex: Int = 0

    public var endIndex: Int  {
      return _result.numberOfFields
    }

    @inlinable
    public var count: Int {
      return endIndex
    }

    @inlinable
    public func index(after i: Int) -> Int {
      return i + 1
    }

    @inlinable
    public func index(before i: Int) -> Int {
      return i - 1
    }

    public subscript(_ index: Int) -> Field {
      let oid = _result.dataTypeOID(at: index)
      let name = _result.columnName(at: index)
      let value = _result.value(at: (rowIndex: rowIndex, columnIndex: index))
      return Field(oid: oid, name: name, value: value)
    }
  }

  /// A query result that represents tuples.
  public final class Table: Equatable, BidirectionalCollection {
    public typealias Element = Row
    public typealias Index = Int

    private let _result: _PGResult

    public static func == (lhs: Table, rhs: Table) -> Bool {
      return lhs._result == rhs._result
    }

    fileprivate init(_ result: _PGResult) {
      self._result = result
    }

    public let startIndex: Int = 0

    public var endIndex: Int {
      return _result.numberOfRows
    }

    @inlinable
    public var count: Int {
      return endIndex
    }

    @inlinable
    public func index(after i: Int) -> Int {
      return i + 1
    }

    @inlinable
    public func index(before i: Int) -> Int {
      return i - 1
    }

    public subscript(_ index: Int) -> Row {
      assert(index >= 0 && index < endIndex, "Out of bounds.")
      return Row(_result, rowIndex: index)
    }
  }

  case ok
  case tuples(Table)
  case singleTuple(Row)
  case copyOut
  case copyIn
  case copyBoth
  case pipelineSynchronization
  case pipelineAborted

  @inlinable
  public var isTuples: Bool {
    guard case .tuples = self else {
      return false
    }
    return true
  }

  @inlinable
  public var isSingleTuple: Bool {
    guard case .singleTuple = self else {
      return false
    }
    return true
  }
}


extension Connection {
  /// A command represented by `query` is submitted to the server.
  public func execute(_ query: Query) throws -> QueryResult {
    guard let pgResult = PQexec(_connection, query.command) else {
      throw ExecutionError.unexpectedError(message: "`PQexec` returned NULL pointer.")
    }
    let status = PQresultStatus(pgResult)
    var dontClear = false
    defer {
      if !dontClear {
        PQclear(pgResult)
      }
    }
    var errorMessage: String { return String(cString: PQresultErrorMessage(pgResult)) }

    switch status {
    case PGRES_EMPTY_QUERY:
      throw ExecutionError.emptyQuery
    case PGRES_COMMAND_OK:
      return .ok
    case PGRES_TUPLES_OK:
      dontClear = true
      return .tuples(QueryResult.Table(QueryResult._PGResult(pgResult)))
    case PGRES_SINGLE_TUPLE:
      dontClear = true
      return .singleTuple(QueryResult.Row(QueryResult._PGResult(pgResult), rowIndex: 0))
    case PGRES_COPY_IN:
      return .copyIn
    case PGRES_COPY_OUT:
      return .copyOut
    case PGRES_COPY_BOTH:
      return .copyBoth
    case PGRES_PIPELINE_SYNC:
      return .pipelineSynchronization
    case PGRES_PIPELINE_ABORTED:
      return .pipelineAborted
    case PGRES_BAD_RESPONSE:
      throw ExecutionError.badResponse(message: errorMessage)
    case PGRES_NONFATAL_ERROR:
      throw ExecutionError.nonFatalError(message: errorMessage)
    case PGRES_FATAL_ERROR:
      throw ExecutionError.fatalError(message: errorMessage)
    default:
      throw ExecutionError.unimplemented
    }
  }
}
