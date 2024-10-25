/* *************************************************************************************************
 QueryResult.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ
import Foundation
import SQLGrammar

/// An error that may be thrown while execution. Some of them are corresponding to `ExecStatusType`.
public enum ExecutionError: Error {
  case tooManyParameters
  case unsupportedResultFormat

  case emptyQuery
  case badResponse(message: String)
  case nonFatalError(message: String)
  case fatalError(message: String)
  case unexpectedError(message: String)

  /// Unimplemented yet...
  case unimplemented
}

private class _Cache<Key, Value>: @unchecked Sendable where Key: Hashable {
  private var _records: [Key: Value] = [:]
  private let _recordsQueue: DispatchQueue = .init(
    label: "jp.YOCKOW.PQ._Cache.\(Key.self).\(Value.self).\(UUID().uuidString)",
    attributes: .concurrent
  )
  private func _withRecords<T>(_ work: (inout [Key: Value]) throws -> T) rethrows -> T {
    return try _recordsQueue.sync(flags: .barrier) { try work(&_records) }
  }

  func value(for key: Key, ifAbsent: () -> Value) -> Value {
    return _withRecords {
      guard let value = $0[key] else {
        let newValue = ifAbsent()
        $0[key] = newValue
        return newValue
      }
      return value
    }
  }
}

private final class _IndexedCache<Value>: _Cache<Int, Value>, @unchecked Sendable {
  func value(at index: Int, ifAbsent: () -> Value) -> Value {
    return super.value(for: index, ifAbsent: ifAbsent)
  }
}

public enum QueryResult: Equatable, Sendable {
  public enum Format: Sendable {
    case text
    case binary

    /// Unknown format.
    case unknown
  }

  /// A field value and its additional information.
  public struct Field: Sendable {
    /// Column name.
    public let name: ColumnIdentifier

    /// Field value.
    public let value: QueryValue

    /// Object Identifier.
    @inlinable
    public var oid: OID {
      return value.oid
    }

    /// A payload of this field.
    @inlinable
    public var payload: QueryValue.Payload? {
      return value.payload
    }

    fileprivate init(name: ColumnIdentifier, value: QueryValue) {
      self.name = name
      self.value = value
    }
  }

  /// Wrapper of a pointer to `PGresult`.
  fileprivate final class _PGResult: Equatable, @unchecked Sendable {
    private let _result: OpaquePointer

    init(_ result: OpaquePointer) {
      self._result = result
    }

    static func == (lhs: _PGResult, rhs: _PGResult) -> Bool {
      return lhs._result == rhs._result
    }

    var staus: ExecStatusType {
      return PQresultStatus(_result)
    }

    var errorMessage: String {
      return String(cString: PQresultErrorMessage(_result))
    }

    private var _cleared: Bool = false
    private let _clearedQueue: DispatchQueue = .init(
      label: "jp.YOCKOW.PQ._PGResult._cleared.\(UUID().uuidString)",
      attributes: .concurrent
    )
    func clear() {
      _clearedQueue.sync(flags: .barrier) {
        if !_cleared {
          PQclear(_result)
          _cleared = true
        }
      }
    }
    deinit {
      clear()
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

    private let _payloadCache: _IndexedCache<_IndexedCache<QueryValue.Payload?>> = .init()
    func payload(at indices: (rowIndex: Int, columnIndex: Int)) -> QueryValue.Payload? {
      return _payloadCache.value(at: indices.rowIndex, ifAbsent: {
        return _IndexedCache<QueryValue.Payload?>()
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
  public final class Row: Equatable, BidirectionalCollection, Sendable {
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
      let name = _result.columnName(at: index)
      let oid = _result.dataTypeOID(at: index)
      let payload = _result.payload(at: (rowIndex: rowIndex, columnIndex: index))
      return Field(name: name, value: QueryValue(oid: oid, payload: payload))
    }
  }

  /// A query result that represents tuples.
  public final class Table: Equatable, BidirectionalCollection, Sendable {
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

    public var numberOfColumns: Int {
      return _result.numberOfFields
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
  private func _handlePGResult(_ result: QueryResult._PGResult) throws -> QueryResult {
    switch result.staus {
    case PGRES_EMPTY_QUERY:
      throw ExecutionError.emptyQuery
    case PGRES_COMMAND_OK:
      return .ok
    case PGRES_TUPLES_OK:
      return .tuples(QueryResult.Table(result))
    case PGRES_SINGLE_TUPLE:
      return .singleTuple(QueryResult.Row(result, rowIndex: 0))
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
      throw ExecutionError.badResponse(message: result.errorMessage)
    case PGRES_NONFATAL_ERROR:
      throw ExecutionError.nonFatalError(message: result.errorMessage)
    case PGRES_FATAL_ERROR:
      throw ExecutionError.fatalError(message: result.errorMessage)
    default:
      throw ExecutionError.unimplemented
    }
  }

  /// A command represented by `query` and given `parameters` are submitted to the server.
  public func execute(
    _ query: Query,
    parameters: [any CustomQueryValueConvertible],
    resultFormat: QueryResult.Format = .text
  ) throws -> QueryResult {
    let count = parameters.count
    guard count <= CInt.max else {
      throw ExecutionError.tooManyParameters
    }

    let cResultFormat: CInt = try ({
      switch resultFormat {
      case .text:
        return 0
      case .binary:
        return 1
      case .unknown:
        throw ExecutionError.unsupportedResultFormat
      }
    })()

    // WORKAROUND FOR https://github.com/swiftlang/swift/issues/77065
    struct __CParameterPointerAssemblage: @unchecked Sendable {
      let count: CInt
      let types: UnsafeMutablePointer<CLibPQ.Oid>
      let values: UnsafeMutablePointer<UnsafePointer<CChar>?>
      let lengths: UnsafeMutablePointer<CInt>
      let formats: UnsafeMutablePointer<CInt>

      init(count: Int) {
        self.count = CInt(count)
        self.types = .allocate(capacity: count)
        self.values = .allocate(capacity: count); values.initialize(repeating: nil, count: count)
        self.lengths = .allocate(capacity: count)
        self.formats = .allocate(capacity: count)
      }

      func deallocateAllPointers() {
        types.deallocate()
        for ii in 0..<Int(count) {
          values[ii]?.deallocate()
        }
        values.deallocate()
        lengths.deallocate()
        formats.deallocate()
      }
    }

    let cParameters = __CParameterPointerAssemblage(count: count)
    defer {
      cParameters.deallocateAllPointers()
    }

    for (ii, param) in parameters.enumerated() {
      let queryValue = param.queryValue
      let cOid = (queryValue.payload == nil ? OID.invalid : param.oid).rawValue
      let payloadData = queryValue.payload?.data
      let payloadPtr: UnsafePointer<CChar>? = payloadData.map {
        let payloadMutablePtr = UnsafeMutablePointer<CChar>.allocate(capacity: $0.count)
        $0.copyBytes(to: UnsafeMutableRawBufferPointer(start: payloadMutablePtr, count: $0.count))
        return UnsafePointer<CChar>(payloadMutablePtr)
      }
      let length: CInt = (payloadData?.count).map(CInt.init) ?? 0
      let format: CInt = ({
        switch queryValue.payload {
        case .text:
          return 0
        case .binary:
          return 1
        case nil:
          return 0 // hmm
        }
      })()

      cParameters.types[ii] = cOid
      cParameters.values[ii] = payloadPtr
      cParameters.lengths[ii] = length
      cParameters.formats[ii] = format
    }

    guard let pgResult = PQexecParams(
      _connection.pointer,
      query.command,
      cParameters.count,
      cParameters.types,
      cParameters.values,
      cParameters.lengths,
      cParameters.formats,
      cResultFormat
    ) else {
      throw ExecutionError.unexpectedError(message: "`PQexecParams` returned NULL pointer.")
    }
    return try _handlePGResult(.init(pgResult))
  }

  /// A command represented by `query` is submitted to the server.
  @inlinable
  public func execute(_ query: Query, resultFormat: QueryResult.Format) throws -> QueryResult {
    return try execute(query, parameters: [], resultFormat: resultFormat)
  }

  /// A command represented by `query` is submitted to the server.
  public func execute(_ query: Query) throws -> QueryResult {
    guard let pgResult = PQexec(_connection.pointer, query.command) else {
      throw ExecutionError.unexpectedError(message: "`PQexec` returned NULL pointer.")
    }
    return try _handlePGResult(.init(pgResult))
  }
}
