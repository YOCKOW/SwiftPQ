/* *************************************************************************************************
 PGConnection.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ
import Foundation
import NetworkGear
import yExtensions

public enum PGConnectionError: Error {
  case fileNotFound
  case unexpectedError(String)
}

public actor PGConnection {
  private var _connection: OpaquePointer // PGconn *
  private var _isFinished: Bool = false

  private init(_ connection: OpaquePointer?) throws {
    guard let pgConn = connection else {
      throw PGConnectionError.unexpectedError("`PGconn *` is NULL pointer.")
    }
    guard PQstatus(pgConn) == CONNECTION_OK else {
      throw PGConnectionError.unexpectedError(String(cString: PQerrorMessage(pgConn)))
    }
    self._connection = pgConn
  }

  private init(uriDescription: String) throws {
    try self.init(PQconnectdb(uriDescription))
  }

  /// Connect the database using UNIX-domain socket in `unixSocketDirectoryPath` directory.
  public init(
    unixSocketDirectoryPath path: String,
    port: UInt16? = nil,
    database: String? = nil,
    user: String? = nil,
    password: String? = nil
  ) throws {
    guard URL(fileURLWithPath: path, isDirectory: true).isExistingLocalDirectory else {
      throw PGConnectionError.fileNotFound
    }
    try self.init(PQsetdbLogin(path, port?.description, nil, nil, database, user, password))
  }

  /// Connect the database on `host`.
  public init(
    host: Domain,
    port: UInt16? = nil,
    database: String? = nil,
    user: String? = nil,
    password: String? = nil
  ) throws {
    try self.init(PQsetdbLogin(host.description, port?.description, nil, nil, database, user, password))
  }

  /// Connect the database on the server with IP address `host`.
  public init(
    host: IPAddress,
    port: UInt16? = nil,
    database: String? = nil,
    user: String? = nil,
    password: String? = nil
  ) throws {
    try self.init(PQsetdbLogin(host.description, port?.description, nil, nil, database, user, password))
  }

  public func finish() {
    if !_isFinished {
      PQfinish(_connection)
      _isFinished = true
    }
  }

  deinit {
    if !_isFinished {
      PQfinish(_connection)
    }
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

  /// Returns IP address of the server.
  public var hostAddress: IPAddress? { _property(PQhostaddr).flatMap(IPAddress.init(string:)) }

  /// Returns the database name of the connection.
  public var database: String? { _property(PQdb) }
}
