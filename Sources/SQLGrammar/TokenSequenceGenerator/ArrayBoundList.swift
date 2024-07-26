/* *************************************************************************************************
 ArrayBoundList.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public final class LeftSquareBracket: Segment {
  public let tokens: [Token] = [.leftSquareBracket, .joiner]
  public static let leftSquareBracket: LeftSquareBracket = .init()
}

public final class RightSquareBracket: Segment {
  public let tokens: [Token] = [.joiner, .rightSquareBracket]
  public static let rightSquareBracket: RightSquareBracket = .init()
}

/// A list that represents `opt_array_bounds` described in "gram.y".
public struct ArrayBoundList: TokenSequenceGenerator {
  public let list: NonEmptyList<UnsignedIntegerConstantExpression?>

  public var tokens: JoinedSQLTokenSequence {
    let sequences: [any TokenSequenceGenerator] = [SingleToken.joiner] + list.map {
      return JoinedSQLTokenSequence.compacting(
        LeftSquareBracket.leftSquareBracket,
        $0,
        RightSquareBracket.rightSquareBracket
      )
    }
    return JoinedSQLTokenSequence(sequences, separator: SingleToken.joiner)
  }

  public init(_ list: NonEmptyList<UnsignedIntegerConstantExpression?>) {
    self.list = list
  }
}

extension ArrayBoundList: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = UnsignedIntegerConstantExpression?

  public init(arrayLiteral elements: UnsignedIntegerConstantExpression?...) {
    guard let list = NonEmptyList<ArrayLiteralElement>(items: elements) else {
      fatalError("Missing unsigned integer expressions.")
    }
    self.init(list)
  }
}
