/* *************************************************************************************************
 CycleClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// `CYCLE` clause that is described as `opt_cycle_clause` in "gram.y".
public struct CycleClause: Clause {
  public let columnNames: ColumnList

  public let cycleMarkColumnName: ColumnIdentifier

  public let cycleMarkValue: (any ConstantExpression)?

  public let cycleMarkDefault: (any ConstantExpression)?

  public let cyclePathColumnName: ColumnIdentifier

  public var tokens: JoinedTokenSequence {
    assert(
      (cycleMarkValue == nil && cycleMarkDefault == nil)
      ||
      (cycleMarkValue != nil && cycleMarkDefault != nil)
    )

    return .compacting(
      SingleToken.cycle,
      columnNames,
      SingleToken.set,
      cycleMarkColumnName.asSequence,
      cycleMarkValue.map({ JoinedTokenSequence([SingleToken.to, $0]) }),
      cycleMarkDefault.map({ JoinedTokenSequence([SingleToken.default, $0]) }),
      SingleToken.using,
      cyclePathColumnName.asSequence
    )
  }

  public init(
    _ columnNames: ColumnList,
    set cycleMarkColumnName: ColumnIdentifier,
    to cycleMarkValue: any ConstantExpression,
    default cycleMarkDefault: any ConstantExpression,
    using cyclePathColumnName: ColumnIdentifier
  ) {
    self.columnNames = columnNames
    self.cycleMarkColumnName = cycleMarkColumnName
    self.cycleMarkValue = cycleMarkValue
    self.cycleMarkDefault = cycleMarkDefault
    self.cyclePathColumnName = cyclePathColumnName
  }

  public init(
    _ columnNames: ColumnList,
    set cycleMarkColumnName: ColumnIdentifier,
    using cyclePathColumnName: ColumnIdentifier
  ) {
    self.columnNames = columnNames
    self.cycleMarkColumnName = cycleMarkColumnName
    self.cycleMarkValue = nil
    self.cycleMarkDefault = nil
    self.cyclePathColumnName = cyclePathColumnName
  }
}
