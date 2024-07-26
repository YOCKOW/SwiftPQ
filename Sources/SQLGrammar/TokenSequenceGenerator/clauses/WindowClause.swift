/* *************************************************************************************************
 WindowClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A window name and its definition. Described as `window_definition` in "gram.y".
public struct WindowDefinition: TokenSequenceGenerator {
  /// Window name.
  public let name: ColumnIdentifier

  /// Window definition.
  public let specification: WindowSpecification

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(name.asSequence, SingleToken(.as), specification)
  }

  public init(name: ColumnIdentifier, specification: WindowSpecification) {
    self.name = name
    self.specification = specification
  }
}

/// A list of window definitions that is described as `window_deinition_list` in "gram.y".
public struct WindowDefinitionList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public let definitions: NonEmptyList<WindowDefinition>

  public var tokens: JoinedSQLTokenSequence {
    return definitions.joinedByCommas()
  }

  public init(_ definitions: NonEmptyList<WindowDefinition>) {
    self.definitions = definitions
  }

  public init(arrayLiteral elements: WindowDefinition...) {
    guard let nonEmptyDefs = NonEmptyList<WindowDefinition>(items: elements) else {
      fatalError("\(Self.self): No definitions?!")
    }
    self.init(nonEmptyDefs)
  }
}

/// `WINDOW` clause that is described as `window_clause` in "gram.y".
public struct WindowClause: Clause {
  public let definitions: WindowDefinitionList

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(SingleToken(.window), definitions)
  }

  public init(_ definitions: WindowDefinitionList) {
    self.definitions = definitions
  }
}
