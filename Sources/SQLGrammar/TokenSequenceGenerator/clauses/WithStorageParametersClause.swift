/* *************************************************************************************************
 WithStorageParametersClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A `WITH` clause used in `CREATE TABLE ...`. This is described as `OptWith` in "gram.y".
public struct WithStorageParametersClause: Clause {
  private enum _Syntax {
    case with(_StorageParameters)
    case withoutOIDs
  }

  private let _syntax: _Syntax

  public var tokens: JoinedTokenSequence {
    switch _syntax {
    case .with(let parameters):
      return JoinedTokenSequence(SingleToken.with, parameters)
    case .withoutOIDs:
      return JoinedTokenSequence(SingleToken.without, SingleToken.oids)
    }
  }

  public var parameters: StorageParameterList {
    switch _syntax {
    case .with(let parameters):
      return parameters.list
    case .withoutOIDs:
      return [.oids: false]
    }
  }

  private init(_syntax: _Syntax) {
    self._syntax = _syntax
  }

  public init(_ list: StorageParameterList) {
    self.init(_syntax: .with(.init(list)))
  }

  /// `WITHOUT OIDS`
  public static let withoutOIDs: WithStorageParametersClause = .init(_syntax: .withoutOIDs)
}
