/* *************************************************************************************************
 Connection.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ
import Foundation
import NetworkGear
import yExtensions

public protocol ConnectionParameter {
  var postgresParameterKey: String { get }
  var postgresParameterValue: String { get }
}

extension ConnectionParameter where Self: RawRepresentable, Self.RawValue == String {
  public var postgresParameterValue: String { rawValue }
}

private protocol _PGHost {
  var _hostDescription: String { get }
}
extension Domain: _PGHost {
  var _hostDescription: String { return description }
}
extension IPAddress: _PGHost {
  var _hostDescription: String {
    switch self {
    case .v4:
      return description
    case .v6:
      return "[\(description)]"
    }
  }
}

public actor Connection {
  public enum Error: Swift.Error {
    case fileNotFound
    case missingUser
    case percentEncodingFailed
    case unexpectedError(String)
  }

  /// GSS TCP/IP connection priority.
  public enum GSSAPIMode: String, ConnectionParameter {
    /// Disable a GSSAPI-encrypted connection.
    case disable

    /// Try a GSSAPI-encrypted connection first. If that fails, try a non-GSSAPI-encrypted connection.
    case prefer

    /// Only try a GSSAPI-encrypted connection.
    case require

    public var postgresParameterKey: String {
      return "gssencmode"
    }
  }

  /// SSL TCP/IP connection priority.
  public enum SSLMode: String, ConnectionParameter {
    /// Disable an SSL connection.
    case disable

    /// Try an SSL connection only if a non-SSL connection fails.
    case allow

    /// Try an SSL connection first. If that fails, try a non-SSL connection.
    case prefer

    /// Only try an SSL connection.
    case require

    /// Only try an SSL connection with verifying that the server certificate is issued 
    /// by a trusted certificate authority.
    case verifyCertificateAuthority = "verify-ca"

    /// Only try an SSL connection with verifying that the server certificate is issued 
    /// by a trusted CA and that the requested server host name matches that in the certificate.
    case verifyFull = "verify-full"

    public var postgresParameterKey: String {
      return "sslmode"
    }
  }

  private var _connection: OpaquePointer // PGconn *
  private var _isFinished: Bool = false

  private init(_ connection: OpaquePointer?) throws {
    guard let pgConn = connection else {
      throw Error.unexpectedError("`PGconn *` is NULL pointer.")
    }
    guard PQstatus(pgConn) == CONNECTION_OK else {
      throw Error.unexpectedError(String(cString: PQerrorMessage(pgConn)))
    }
    self._connection = pgConn
  }

  private init(uriDescription: String) throws {
    try self.init(PQconnectdb(uriDescription))
  }

  private init(
    _host host: any _PGHost,
    port: UInt16?,
    database: String?,
    user: String?,
    password: String?,
    parameters: [any ConnectionParameter]
  ) throws {
    var uriDescription = "postgresql://"

    switch (user, password) {
    case (let user?, let password?):
      uriDescription += "\(user):\(password)@"
    case (let user?, nil):
      uriDescription += "\(user)@"
    case (nil, _?):
      throw Error.missingUser
    case (nil, nil):
      break
    }

    uriDescription += "\(host._hostDescription)"

    if let port {
      uriDescription += ":\(port.description)"
    }

    if let database {
      guard let encodedDatabaseName = database.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
        throw Error.percentEncodingFailed
      }
      uriDescription += "/\(encodedDatabaseName)"
    }

    if !parameters.isEmpty {
      uriDescription += "?"
      uriDescription += try parameters.map({
        guard let encodedKey = $0.postgresParameterKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedValue = $0.postgresParameterValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
          throw Error.percentEncodingFailed
        }
        return "\(encodedKey)=\(encodedValue)"
      }).joined(separator: "&")
    }

    try self.init(uriDescription: uriDescription)
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
      throw Error.fileNotFound
    }
    try self.init(PQsetdbLogin(path, port?.description, nil, nil, database, user, password))
  }

  /// Connect the database on `host`.
  public init(
    host: Domain,
    port: UInt16? = nil,
    database: String? = nil,
    user: String? = nil,
    password: String? = nil,
    parameters: [any ConnectionParameter]? = nil
  ) throws {
    if let parameters {
      try self.init(_host: host, port: port, database: database, user: user, password: password, parameters: parameters)
    } else {
      try self.init(PQsetdbLogin(host.description, port?.description, nil, nil, database, user, password))
    }
  }

  /// Connect the database on the server with IP address `host`.
  public init(
    host: IPAddress,
    port: UInt16? = nil,
    database: String? = nil,
    user: String? = nil,
    password: String? = nil,
    parameters: [any ConnectionParameter]? = nil
  ) throws {
    if let parameters {
      try self.init(_host: host, port: port, database: database, user: user, password: password, parameters: parameters)
    } else {
      try self.init(PQsetdbLogin(host.description, port?.description, nil, nil, database, user, password))
    }
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
