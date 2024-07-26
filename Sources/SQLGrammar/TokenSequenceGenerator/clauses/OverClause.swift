/* *************************************************************************************************
 OverClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause that is described as `over_clause` in "gram.y".
public struct OverClause: Clause {
  private enum _Window {
    case specification(WindowSpecification)
    case name(ColumnIdentifier)
  }

  private let _window: _Window

  public var tokens: JoinedSQLTokenSequence {
    switch _window {
    case .specification(let spec):
      return JoinedSQLTokenSequence(SingleToken.over, spec)
    case .name(let id):
      return JoinedSQLTokenSequence(SingleToken.over, SingleToken(id))
    }
  }

  public var windowSpecification: WindowSpecification? {
    guard case .specification(let spec) = _window else {
      return nil
    }
    return spec
  }

  public var windowName: ColumnIdentifier? {
    guard case .name(let id) = _window else {
      return nil
    }
    return id
  }

  public init(windowSpecification: WindowSpecification) {
    self._window = .specification(windowSpecification)
  }

  public init(windowName: ColumnIdentifier) {
    self._window = .name(windowName)
  }
}
