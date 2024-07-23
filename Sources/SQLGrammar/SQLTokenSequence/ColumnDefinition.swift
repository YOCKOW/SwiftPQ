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

  public let genericOptions: GenericOptionsClause?

  public let qualifiers: ColumnQualifierList?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting(
      name.asSequence,
      dataType,
      storageMode,
      compressionMode,
      genericOptions,
      qualifiers
    )
  }

  public init(
    name: ColumnIdentifier,
    dataType: TypeName,
    storageMode: ColumnStorageMode? = nil,
    compressionMode: ColumnCompressionMode? = nil,
    genericOptions: GenericOptionsClause? = nil,
    qualifiers: ColumnQualifierList? = nil
  ) {
    self.name = name
    self.dataType = dataType
    self.storageMode = storageMode
    self.compressionMode = compressionMode
    self.genericOptions = genericOptions
    self.qualifiers = qualifiers
  }
}
