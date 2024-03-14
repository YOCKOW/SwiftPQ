/* *************************************************************************************************
 AnyNameList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a list that is described as `any_name_list` in "gram.y".
public struct AnyNameList: SQLTokenSequence {
  public let names: NonEmptyList<AnyName>

  public init(names: NonEmptyList<AnyName>) {
    self.names = names
  }

  public var tokens: JoinedSQLTokenSequence {
    return names.joinedByCommas()
  }
}

extension AnyNameList: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = AnyName

  @inlinable
  public init(arrayLiteral elements: AnyName...) {
    guard let names = NonEmptyList<AnyName>(items: elements) else {
      fatalError("List must not be empty.")
    }
    self.init(names: names)
  }
}
