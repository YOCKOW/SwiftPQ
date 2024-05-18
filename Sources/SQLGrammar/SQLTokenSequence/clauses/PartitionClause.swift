/* *************************************************************************************************
 PartitionClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private final class _PartitionBy: Segment {
  let tokens: Array<SQLToken> = [.partition, .by]
  private init() {}
  static let partitionBy: _PartitionBy = .init()
}

/// A clause that is described as `opt_partition_clause` in "gram.y".
public struct PartitionClause: Clause {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(_PartitionBy.partitionBy, expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }
}
