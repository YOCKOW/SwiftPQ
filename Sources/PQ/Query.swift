/* *************************************************************************************************
 Query.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ
import SQLGrammar

/// A type representing SQL.
public struct Query {
  public struct RawSQL: RawRepresentable,
                        ExpressibleByStringLiteral,
                        ExpressibleByStringInterpolation {
    public typealias RawValue = String
    public typealias StringLiteralType = String

    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
      self.init(rawValue: value)
    }

    public struct StringInterpolation: StringInterpolationProtocol {
      public typealias StringLiteralType = String

      fileprivate enum _Element {
        case string(String)
        case token(Token)
        case tokenSequence(any TokenSequenceGenerator)

        var description: String {
          switch self {
          case .string(let string):
            return string.description
          case .token(let token):
            return token.description
          case .tokenSequence(let sequence):
            return sequence.description
          }
        }
      }

      fileprivate var _elements: [_Element]

      public init(literalCapacity: Int, interpolationCount: Int) {
        self._elements = .init()
        self._elements.reserveCapacity(literalCapacity + interpolationCount + 1)
      }

      public mutating func appendLiteral(_ literal: String) {
        _elements.append(.string(literal))
      }

      public mutating func appendInterpolation<S>(raw string: S) where S: StringProtocol {
        _elements.append(.string(String(string)))
      }

      public mutating func appendInterpolation(_ token: Token) {
        _elements.append(.token(token))
      }

      public mutating func appendInterpolation<T>(_ tokens: T) where T: TokenSequenceGenerator {
        _elements.append(.tokenSequence(tokens))
      }

      @inlinable
      public mutating func appendInterpolation<S>(
        identifier: S,
        forceQuoting: Bool = false,
        encodingIsUTF8: Bool = true
      ) where S: StringProtocol {
        self.appendInterpolation(
          .identifier(String(identifier), forceQuoting: forceQuoting, encodingIsUTF8: encodingIsUTF8)
        )
      }

      @inlinable
      public mutating func appendInterpolation<S>(literal: S, encodingIsUTF8: Bool = true) where S: StringProtocol {
        self.appendInterpolation(.string(String(literal), encodingIsUTF8: encodingIsUTF8))
      }

      @inlinable
      public mutating func appendInterpolation<T>(integer: T) where T: SQLIntegerType {
        self.appendInterpolation(.integer(integer))
      }

      @inlinable
      public mutating func appendInterpolation<T>(float: T) where T: SQLFloatType {
        self.appendInterpolation(.float(float))
      }
    }

    public init(stringInterpolation: StringInterpolation) {
      self.init(rawValue: stringInterpolation._elements.reduce(into: "", { $0 += $1.description }))
    }
  }

  public let command: String

  private init(_ command: String) {
    self.command = command
  }

  /// Create an instance with `command`.
  ///
  /// - Warning: This method does NOT escape any characters contained in `command`.
  ///   It is fraught with risk of SQL injection. Avoid using this method directly if possible.
  public static func rawSQL(_ command: RawSQL) -> Query {
    return .init(command.rawValue)
  }

  /// Creates an instance with `mode`.
  public static func mode(_ mode: RawParseMode) -> Query {
    return .init(mode.description)
  }

  /// Creates an instance with the given list of statements.
  @inlinable
  public static func query(from statements: StatementList) -> Query {
    return .mode(.default(statements))
  }

  /// Creates an instance with the given statement(s).
  @inlinable
  public static func query<FirstStatement, each AdditionalStatement>(
    from firstStatement: FirstStatement,
    _ additionalStatement: repeat each AdditionalStatement
  ) -> Query where FirstStatement: TopLevelStatement,
                   repeat each AdditionalStatement: TopLevelStatement
  {
    return .query(from: StatementList(firstStatement, repeat each additionalStatement))
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
