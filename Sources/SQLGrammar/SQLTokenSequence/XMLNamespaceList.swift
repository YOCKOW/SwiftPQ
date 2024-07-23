
/* *************************************************************************************************
 XMLNamespaceList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element of XML namespace list that is described as `xml_namespace_el` in "gram.y".
public struct XMLNamespaceListElement: SQLTokenSequence {
  public enum Name {
    case name(ColumnLabel)
    case `default`
  }

  public let uri: any RestrictedExpression

  public let name: Name

  public var tokens: JoinedSQLTokenSequence {
    switch name {
    case .name(let namespaceName):
      return JoinedSQLTokenSequence([
        uri,
        SingleToken(.as),
        namespaceName.asSequence
      ] as [any SQLTokenSequence])
    case .default:
      return JoinedSQLTokenSequence([SingleToken(.default), uri] as [any SQLTokenSequence])
    }
  }

  public init(uri: any RestrictedExpression, name: Name) {
    self.uri = uri
    self.name = name
  }

  public init(uri: any RestrictedExpression, `as` name: ColumnLabel) {
    self.init(uri: uri, name: .name(name))
  }

  public init(uri: any RestrictedExpression) {
    self.init(uri: uri, name: .default)
  }
}

/// A list that is described as `xml_namespace_list` in "gram.y".
public struct XMLNamespaceList: SQLTokenSequence, ExpressibleByArrayLiteral {
  public let elements: NonEmptyList<XMLNamespaceListElement>

  public var tokens: JoinedSQLTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<XMLNamespaceListElement>) {
    self.elements = elements
  }

  public init(arrayLiteral elements: XMLNamespaceListElement...) {
    guard let list = NonEmptyList(items: elements) else {
      fatalError("\(Self.self): No elements?!")
    }
    self.init(list)
  }
}
