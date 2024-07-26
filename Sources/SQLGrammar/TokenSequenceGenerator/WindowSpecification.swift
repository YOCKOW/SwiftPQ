/* *************************************************************************************************
 WindowSpecification.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A representation of`window_specification` in "gram.y"
public struct WindowSpecification: TokenSequenceGenerator {
  /// Existing window name.
  public let name: ColumnIdentifier?

  public let partitionBy: PartitionClause?

  public let orderBy: SortClause?

  public let frame: FrameClause?

  public var tokens: Parenthesized<JoinedSQLTokenSequence> {
    return Parenthesized<JoinedSQLTokenSequence>(
      .compacting(name?.asSequence, partitionBy, orderBy, frame)
    )
  }

  public init(
    name: ColumnIdentifier?,
    partitionBy: PartitionClause?,
    orderBy: SortClause?,
    frame: FrameClause?
  ) {
    self.name = name
    self.partitionBy = partitionBy
    self.orderBy = orderBy
    self.frame = frame
  }
}
