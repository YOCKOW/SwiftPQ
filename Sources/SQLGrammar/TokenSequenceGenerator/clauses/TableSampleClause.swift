/* *************************************************************************************************
 TableSampleClause.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A clause to be used in `opt_repeatable_clause`.
public struct RepeatableClause<Seed>: Clause where Seed: GeneralExpression {
  public let seed: Seed

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence(
      SingleToken.repeatable,
      SingleToken.joiner,
      seed.parenthesized
    )
  }

  public init(seed: Seed) {
    self.seed = seed
  }
}

/// A clause described as `tablesample_clause` in "gram.y".
public struct TableSampleClause: Clause {
  public let samplingMethod: FunctionName

  public let arguments: GeneralExpressionList

  public struct Repeatable: Clause {
    private class _Box {
      var tokens: JoinedTokenSequence {
        fatalError("Must be overridden.")
      }

      func specifySeed<T>(_ seed: T.Type) -> RepeatableClause<T>? where T: GeneralExpression {
        fatalError("Must be overridden.")
      }
    }

    private final class _Base<Seed>: _Box where Seed: GeneralExpression {
      private let _base: RepeatableClause<Seed>

      init(_ base: RepeatableClause<Seed>) {
        self._base = base
      }
      
      override var tokens: JoinedTokenSequence {
        return _base.tokens
      }

      override func specifySeed<T>(_ seed: T.Type) -> RepeatableClause<T>? where T: GeneralExpression {
        return _base as? RepeatableClause<T>
      }
    }

    private let _box: _Box

    public var tokens: JoinedTokenSequence {
      return _box.tokens
    }

    public init<Seed>(_ clause: RepeatableClause<Seed>) where Seed: GeneralExpression {
      self._box = _Base<Seed>(clause)
    }

    public func specifySeed<Seed>(_ seed: Seed.Type) -> RepeatableClause<Seed>? where Seed: GeneralExpression {
      return _box.specifySeed(seed)
    }
  }

  public let repeatable: Repeatable?

  public var tokens: JoinedTokenSequence {
    return JoinedTokenSequence.compacting(
      SingleToken.tablesample,
      samplingMethod,
      SingleToken.joiner,
      arguments.parenthesized,
      repeatable
    )
  }

  public init(
    samplingMethod: FunctionName,
    arguments: GeneralExpressionList,
    repeatable: Repeatable? = nil
  ) {
    self.samplingMethod = samplingMethod
    self.arguments = arguments
    self.repeatable = repeatable
  }

  public init<Seed>(
    samplingMethod: FunctionName,
    arguments: GeneralExpressionList,
    repeatable: RepeatableClause<Seed>
  ) where Seed: GeneralExpression {
    self.samplingMethod = samplingMethod
    self.arguments = arguments
    self.repeatable = .init(repeatable)
  }
}
