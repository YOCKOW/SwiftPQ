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
    return .init(tokens._description)
  }

  /// Create a query containing multiple commands with `separator`. Default separator is "; ".
  public static func joining<S1, S2>(
    _ tokenSequences: S1,
    separator: S2 = Array<SQLToken>([.joiner, .semicolon])
  ) -> Query where S1: Sequence, S1.Element: Sequence, S1.Element.Element == SQLToken,
                   S2: Sequence, S2.Element == SQLToken
  {
    return query(from: tokenSequences.joined(separator: separator))
  }
}

extension String.StringInterpolation {
  public mutating func appendInterpolation(_ token: SQLToken) {
    self.appendLiteral(token.description)
  }

  public mutating func appendInterpolation<T>(_ tokens: T) where T: SQLTokenSequence {
    self.appendLiteral(tokens.description)
  }
}

extension Query {
  public static func dropTable(_ tableName: TableName, ifExists: Bool = false) -> Query {
    var tokens: [SQLToken] = [.drop, .table]
    if ifExists {
      tokens.append(contentsOf: [.if, .exists])
    }
    tokens.append(contentsOf: tableName)
    tokens.append(contentsOf: [.joiner, .semicolon])
    return .query(from: tokens)
  }

  public static func dropTable(schema: String? = nil, name: String, ifExists: Bool = false) -> Query {
    return dropTable(TableName(schema: schema, name: name), ifExists: ifExists)
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
