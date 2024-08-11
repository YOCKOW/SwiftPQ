/* *************************************************************************************************
 QueryResult.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ

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

public enum QueryResult: Equatable {
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
  }

  public enum Format {
    case text
    case binary
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
    public let name: String

    /// Field value.
    public let value: QueryResult.Value

    fileprivate init(oid: OID, name: String, value: QueryResult.Value) {
      self.oid = oid
      self.name = name
      self.value = value
    }
  }

  /// Representation of a row (a.k.a. tuple).
  public final class Row: Equatable {
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
  }

  /// A query result that represents tuples.
  public final class Table: Equatable {
    private let _result: _PGResult

    public static func == (lhs: Table, rhs: Table) -> Bool {
      return lhs._result == rhs._result
    }

    fileprivate init(_ result: _PGResult) {
      self._result = result
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
