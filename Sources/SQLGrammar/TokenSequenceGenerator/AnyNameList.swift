/* *************************************************************************************************
 AnyNameList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing a list that is described as `any_name_list` in "gram.y".
public struct AnyNameList: TokenSequenceGenerator {
  public let names: NonEmptyList<any AnyName>

  public init(names: NonEmptyList<any AnyName>) {
    self.names = names
  }

  public var tokens: JoinedTokenSequence {
    return names.map({ $0 as any TokenSequenceGenerator }).joinedByCommas()
  }
}

extension AnyNameList: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = AnyName

  @inlinable
  public init(arrayLiteral elements: (any AnyName)...) {
    guard let names = NonEmptyList<any AnyName>(items: elements) else {
      fatalError("List must not be empty.")
    }
    self.init(names: names)
  }
}
