/* *************************************************************************************************
 ReferentialAction.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An action performed when the data in the referenced columns is changed. This is described as
/// `key_action` in "gram.y".
public enum ReferentialAction: SQLTokenSequence {
  case noAction
  case restrict
  case cascade
  case setNull(OptionalColumnList)
  case setDefault(OptionalColumnList)

  public var tokens: JoinedSQLTokenSequence {
    switch self {
    case .noAction:
      return JoinedSQLTokenSequence(SingleToken(.no), SingleToken(.action))
    case .restrict:
      return JoinedSQLTokenSequence(SingleToken(.restrict))
    case .cascade:
      return JoinedSQLTokenSequence(SingleToken(.cascade))
    case .setNull(let list):
      return JoinedSQLTokenSequence(SingleToken(.set), SingleToken(.null), list)
    case .setDefault(let list):
      return JoinedSQLTokenSequence(SingleToken(.set), SingleToken(.default), list)
    }
  }
}

/// A set of `ReferentialAction`s. Described as `key_actions` in "gram.y".
public struct ReferentialActionSet: SQLTokenSequence {
  public class Action: SQLTokenSequence {
    public let action: ReferentialAction

    fileprivate init(_ action: ReferentialAction) {
      self.action = action
    }

    public var tokens: JoinedSQLTokenSequence { fatalError("Must be overridden.") }

    /// `key_delete` in "gram.y".
    public final class OnDelete: Action {
      public override var tokens: JoinedSQLTokenSequence {
        return JoinedSQLTokenSequence(SingleToken(.on), SingleToken(.delete), action)
      }
    }

    /// `key_update` in "gram.y".
    public final class OnUpdate: Action {
      public override var tokens: JoinedSQLTokenSequence {
        return JoinedSQLTokenSequence(SingleToken(.on), SingleToken(.update), action)
      }
    }

    fileprivate static func onDelete(_ action: ReferentialAction) -> Action {
      return OnDelete(action)
    }

    fileprivate static func onUpdate(_ action: ReferentialAction) -> Action {
      return OnUpdate(action)
    }
  }

  public let actions: Array<Action>

  public var tokens: JoinedSQLTokenSequence {
    return actions.joined()
  }

  public init(onDelete: ReferentialAction) {
    self.actions = [.onDelete(onDelete)]
  }

  public init(onUpdate: ReferentialAction) {
    self.actions = [.onUpdate(onUpdate)]
  }

  public init(onDelete: ReferentialAction, onUpdate: ReferentialAction) {
    self.actions = [.onDelete(onDelete), .onUpdate(onUpdate)]
  }

  public init(onUpdate: ReferentialAction, onDelete: ReferentialAction) {
    self.actions = [.onUpdate(onUpdate), .onDelete(onDelete)]
  }
}
