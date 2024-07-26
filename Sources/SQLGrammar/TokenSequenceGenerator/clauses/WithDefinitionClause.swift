/* *************************************************************************************************
 WithDefinitionClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A `WITH` clause of `definition`. This represents `opt_definition` in "gram.y".
public struct WithDefinitionClause: Clause {
  public let definition: Definition

  @inlinable
  public var definitionList: DefinitonList {
    return definition.list
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(SingleToken.with, definition)
  }

  public init(_ definition: Definition) {
    self.definition = definition
  }

  public init(_ list: DefinitonList) {
    self.definition = Definition(list)
  }
}
