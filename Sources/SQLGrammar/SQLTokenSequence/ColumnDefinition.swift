/* *************************************************************************************************
 ColumnDefinition.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Definition for a column. This is described as `columnDef` in "gram.y".
public struct ColumnDefinition: SQLTokenSequence {
  /// Column name.
  public let name: ColumnIdentifier

  /// Type of the column.
  public let dataType: TypeName

  public let storageMode: ColumnStorageMode?

  public let compressionMode: ColumnCompressionMode?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      name.asSequence,
      dataType,
      storageMode,
      compressionMode
    )
  }
}
