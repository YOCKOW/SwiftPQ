/* *************************************************************************************************
 GroupClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An empty grouping set that is described as `empty_grouping_set` in "gram.y".
public final class EmptyGroupingSet: TokenSequence {
  public let tokens: Array<Token> = [.leftParenthesis, .joiner, .rightParenthesis]
  private init() {}
  public static let emptyGroupingSet: EmptyGroupingSet = .init()
}

/// `CUBE` clause used in group clause, that is described as `cube_clause` in "gram.y".
public struct CubeClause: Clause {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedTokenSequence {
    return SingleToken.cube.followedBy(parenthesized: expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }
}

/// `ROLLUP` clause used in group clause, that is described as `rollup_clause` in "gram.y".
public struct RollUpClause: Clause {
  public let expressions: GeneralExpressionList

  public var tokens: JoinedTokenSequence {
    return SingleToken.rollup.followedBy(parenthesized: expressions)
  }

  public init(_ expressions: GeneralExpressionList) {
    self.expressions = expressions
  }
}

/// `GROUPING SETS` clause used in group clause, that is described as `grouping_sets_clause` in "gram.y".
public struct GroupingSetsClause: Clause {
  public let list: GroupingList

  private final class _GroupingSetsTokens: TokenSequenceGenerator {
    let tokens: Array<Token> = [.grouping, .sets]
    private init() {}
    static let groupingSetsTokens: _GroupingSetsTokens = .init()
  }

  public var tokens: JoinedTokenSequence {
    return _GroupingSetsTokens.groupingSetsTokens.followedBy(parenthesized: list)
  }

  public init(_ list: GroupingList) {
    self.list = list
  }
}

/// An element used in `GROUP BY` clause, that is described as `group_by_item` in "gram.y".
public enum GroupingElement: TokenSequenceGenerator {
  case expression(any GeneralExpression)
  case empty
  case cube(CubeClause)
  case rollUp(RollUpClause)
  case groupingSets(GroupingSetsClause)

  public struct Tokens: Sequence {
    public typealias Element = Token
    private let _tokens: AnyTokenSequenceGenerator

    public struct Iterator: IteratorProtocol {
      public typealias Element = Token
      private var _iterator: AnyTokenSequenceIterator
      public mutating func next() -> Token? { return _iterator.next() }
      fileprivate init(_ iterator: AnyTokenSequenceIterator) {
        self._iterator = iterator
      }
    }

    public func makeIterator() -> Iterator {
      return Iterator(_tokens._anyIterator)
    }

    fileprivate init<S>(_ tokens: S) where S: TokenSequenceGenerator {
      self._tokens = AnyTokenSequenceGenerator(tokens)
    }
  }

  public var tokens: Tokens {
    switch self {
    case .expression(let expr):
      return Tokens(expr._asAny)
    case .empty:
      return Tokens(EmptyGroupingSet.emptyGroupingSet)
    case .cube(let cubeClause):
      return Tokens(cubeClause)
    case .rollUp(let rollUpClause):
      return Tokens(rollUpClause)
    case .groupingSets(let groupingSetsClause):
      return Tokens(groupingSetsClause)
    }
  }

  public init(_ expression: any GeneralExpression) {
    self = .expression(expression)
  }

  public init() {
    self = .empty
  }

  public init(cube expressions: GeneralExpressionList) {
    self = .cube(CubeClause(expressions))
  }

  public init(rollUp expressions: GeneralExpressionList) {
    self = .rollUp(RollUpClause(expressions))
  }

  public init(groupingSets list: GroupingList) {
    self = .groupingSets(GroupingSetsClause(list))
  }
}

/// A list of `GroupingElement`, that is described as `group_by_list` in "gram.y".
public struct GroupingList: TokenSequenceGenerator, ExpressibleByArrayLiteral {
  public let elements: NonEmptyList<GroupingElement>

  public var tokens: JoinedTokenSequence {
    return elements.joinedByCommas()
  }

  public init(_ elements: NonEmptyList<GroupingElement>) {
    self.elements = elements
  }

  public init(arrayLiteral elements: GroupingElement...) {
    guard let nonEmptyElements = NonEmptyList<GroupingElement>(items: elements) else {
      fatalError("\(Self.self): No elements?!")
    }
    self.init(nonEmptyElements)
  }
}


/// `GROUP BY` clause that is described as `group_clause` in "gram.y".
public struct GroupClause: Clause {
  public let quantifier: SetQuantifier?

  public let columnReferences: GroupingList

  private final class _GroupByTokens: Segment {
    let tokens: Array<Token> = [.group, .by]
    private init() {}
    static let groupByTokens: _GroupByTokens = .init()
  }

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence.compacting(
      _GroupByTokens.groupByTokens,
      quantifier?.asSequence,
      columnReferences
    )
  }

  public init(quantifier: SetQuantifier? = nil, columnReferences: GroupingList) {
    self.quantifier = quantifier
    self.columnReferences = columnReferences
  }
}
