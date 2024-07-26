/* *************************************************************************************************
 WhenClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A `WHEN ... THEN ...` clause used in `CaseExpression`.
public struct WhenClause<Condition, Result>: Clause where Condition: GeneralExpression,
                                                          Result: GeneralExpression {

  public let condition: Condition

  public let result: Result

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(
      SingleToken.when, condition,
      SingleToken.then, result
    )
  }

  public init(when condition: Condition, then result: Result) {
    self.condition = condition
    self.result = result
  }
}

/// A type-erasure for `WhenClause`.
struct AnyWhenClause: Clause {
  private class _Box {
    var condition: any GeneralExpression { fatalError("Must be overridden.") }
    var result: any GeneralExpression { fatalError("Must be overridden.") }
    var tokens: JoinedTokenSequence { fatalError("Must be overridden.") }
  }
  private class _Base<C, R>: _Box where C: GeneralExpression, R: GeneralExpression {
    let _base: WhenClause<C, R>
    init(_ base: WhenClause<C, R>) { self._base = base }

    override var condition: any GeneralExpression { _base.condition }
    override var result: any GeneralExpression { _base.result }
    override var tokens: JoinedTokenSequence { _base.tokens }
  }

  private let _box: _Box

  var condition: any GeneralExpression { _box.condition }

  var result: any GeneralExpression { _box.result }

  var tokens: JoinedTokenSequence { _box.tokens }

  func `as`<Condition, Result>(
    _ expectedType: WhenClause<Condition, Result>.Type
  ) -> WhenClause<Condition, Result>? {
    return (_box as? _Base<Condition, Result>)?._base
  }

  init<Condition, Result>(_ base: WhenClause<Condition, Result>) where Condition: GeneralExpression,
                                                                       Result: GeneralExpression {
    self._box = _Base<Condition, Result>(base)
  }

  init<Condition, Result>(
    when condition: Condition,
    then result: Result
  ) where Condition: GeneralExpression, Result: GeneralExpression {
    self.init(WhenClause<Condition, Result>(when: condition, then: result))
  }
}

/// A list of "when clause", that is described as `when_clause_list` in "gram.y".
public struct WhenClauseList: TokenSequenceGenerator {
  private var _clauses: NonEmptyList<AnyWhenClause>

  public var tokens: JoinedTokenSequence {
    return _clauses.joined()
  }

  public init<Condition, Result, each OptionalCondition, each OptionalResult>(
    _ firstClause: WhenClause<Condition, Result>,
    _ optionalClause: repeat WhenClause<each OptionalCondition, each OptionalResult>
  ) where Condition: GeneralExpression, Result: GeneralExpression,
          repeat each OptionalCondition: GeneralExpression,
          repeat each OptionalResult: GeneralExpression
  {
    var list = NonEmptyList(item: AnyWhenClause(firstClause))
    repeat (list.append(AnyWhenClause(each optionalClause)))
    self._clauses = list
  }

  public init<Condition, Result, each OptionalCondition, each OptionalResult>(
    _ firstClauseSeed: (when: Condition, then: Result),
    _ optionalClauseSeed: repeat (when: each OptionalCondition, then: each OptionalResult)
  ) where Condition: GeneralExpression, Result: GeneralExpression,
          repeat each OptionalCondition: GeneralExpression,
          repeat each OptionalResult: GeneralExpression
  {
    var list = NonEmptyList(item: AnyWhenClause(when: firstClauseSeed.0, then: firstClauseSeed.1))
    repeat (list.append(
      AnyWhenClause(when: (each optionalClauseSeed).0, then: (each optionalClauseSeed).1))
    )
    self._clauses = list
  }

  public mutating func append<Condition, Result>(
    _ whenClause: WhenClause<Condition, Result>
  ) where Condition: GeneralExpression, Result: GeneralExpression {
    _clauses.append(AnyWhenClause(whenClause))
  }

  public mutating func append<Condition, Result>(
    when condition: Condition,
    then result: Result
  ) where Condition: GeneralExpression, Result: GeneralExpression {
    self.append(WhenClause<Condition, Result>(when: condition, then: result))
  }
}
