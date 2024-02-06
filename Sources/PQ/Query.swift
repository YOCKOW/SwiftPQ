/* *************************************************************************************************
 Query.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ

/// A type representing SQL.
public struct Query {
  public let command: String

  private init(_ command: String) {
    self.command = command
  }

  /// Create an instance with `command`.
  ///
  /// - Warning: This method does NOT escape any characters contained in `command`.
  ///   It is fraught with risk of SQL injection. Avoid using this method directly if possible.
  public static func rawSQL(_ command: String) -> Query {
    return .init(command)
  }

  /// Create a query concatenating `tokens`.
  public static func query<S>(from tokens: S) -> Query where S: Sequence, S.Element == SQLToken {
    return .init(tokens.map(\.description).joined(separator: " "))
  }
}

extension Query {
  public static func dropTable(scheme: String? = nil, name: String, ifExists: Bool = false) -> Query {
    var tokens: [SQLToken] = [.drop, .table]
    if ifExists {
      tokens.append(contentsOf: [.if, .exists])
    }
    if let scheme {
      tokens.append(contentsOf: [.identifier(scheme), .dot])
    }
    tokens.append(.identifier(name))
    tokens.append(.semicolon)

    return .query(from: tokens)
  }
}

public enum ExecutionError: Error {
  case emptyQuery
  case badResponse(message: String)
  case nonFatalError(message: String)
  case fatalError(message: String)
  case unexpectedError(message: String)

  /// Unimplemented yet...
  case unimplemented
}

public enum ExecutionResult {
  case ok
  // case tuples()
  // case singleTuple()
  case copyOut
  case copyIn
  case copyBoth
  case pipelineSynchronization
  case pipelineAborted
}

extension Connection {
  /// A command represented by `query` is submitted to the server.
  public func execute(_ query: Query) throws -> ExecutionResult {
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
      throw ExecutionError.unimplemented
    case PGRES_SINGLE_TUPLE:
      throw ExecutionError.unimplemented
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
