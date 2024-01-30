/* *************************************************************************************************
 PGConnection.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ
import Foundation

public enum PGConnectionError: Error {
  case fileNotFound
  case percentEncodingFailed

  case unexpectedError(String)
}

public actor PGConnection {
  private var _connection: OpaquePointer // PGconn *

  private init(_connection: OpaquePointer) {
    self._connection = _connection
  }

  private init(uriDescription: String) throws {
    guard let pgConn = PQconnectdb(uriDescription) else {
      throw PGConnectionError.unexpectedError("PQconnectdb returned NULL pointer.")
    }
    guard PQstatus(pgConn) == CONNECTION_OK else {
      throw PGConnectionError.unexpectedError(String(cString: PQerrorMessage(pgConn)))
    }
    self.init(_connection: pgConn)
  }

  /// Connect the database using UNIX-domain socket in `unixSocketDirectoryPath` directory.
  public init(
    unixSocketDirectoryPath path: String,
    port: UInt16? = nil,
    database: String? = nil,
    user: String? = nil,
    password: String? = nil
  ) throws {
    guard path.hasPrefix("/") && FileManager.default.fileExists(atPath: path) else {
      throw PGConnectionError.fileNotFound
    }
    guard let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
      throw PGConnectionError.percentEncodingFailed
    }
    var uri = "postgresql://\(escapedPath)"
    if let port {
      uri += ":\(port.description)"
    }
    if let database {
      uri += "/\(database)"
    }

    var params: [(name: String, value: String)] = []
    if let user {
      params.append((name: "user", value: user))
    }
    if let password {
      params.append((name: "password", value: password))
    }
    if !params.isEmpty {
      uri += "?"
      for (ii, item) in params.enumerated() {
        uri += "\(item.name)="
        guard let escapedValue = item.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
          throw PGConnectionError.percentEncodingFailed
        }
        uri += escapedValue
        if ii < params.count - 1 {
          uri += "&"
        }
      }
    }

    try self.init(uriDescription: uri)
  }

  deinit {
    PQfinish(_connection)
  }

  private func _property(_ pqFunc: (OpaquePointer) -> UnsafeMutablePointer<CChar>?) -> String? {
    guard let cString = pqFunc(_connection) else { return nil }
    return String(cString: cString)
  }

  /// Returns the user name of the connection.
  public var user: String? { _property(PQuser) }

  /// Returns the password of the connection.
  public var password: String? { _property(PQpass) }

  /// Returns the server host name of the active connection.
  public var host: String? { _property(PQhost) }

  /// Returns the database name of the connection.
  public var database: String? { _property(PQdb) }
}
