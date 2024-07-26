/* *************************************************************************************************
 XMLAttributeList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A representation of XML attribute that is described as `xml_attribute_el` in "gram.y".
public struct XMLAttribute: TokenSequenceGenerator {
  public let name: ColumnLabel?

  public let value: any GeneralExpression

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(
      [
        value,
        name.map(SingleToken.init),
      ] as [(any TokenSequenceGenerator)?],
      separator: SingleToken.as
    )
  }

  public init(name: ColumnLabel?, value: any GeneralExpression) {
    self.name = name
    self.value = value
  }

  @inlinable
  public init(name: ColumnLabel?, value: StringConstantExpression) {
    self.name = name
    self.value = value
  }
}

/// A list of XML attributes that is described as `xml_attribute_list` in "gram.y".
public struct XMLAttributeList: TokenSequenceGenerator {
  public let attributes: NonEmptyList<XMLAttribute>

  public var tokens: JoinedSQLTokenSequence {
    return attributes.joinedByCommas()
  }

  public init(_ attributes: NonEmptyList<XMLAttribute>) {
    self.attributes = attributes
  }
}
