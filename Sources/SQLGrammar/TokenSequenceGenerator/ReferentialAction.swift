/* *************************************************************************************************
 ReferentialAction.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An action performed when the data in the referenced columns is changed. This is described as
/// `key_action` in "gram.y".
public enum ReferentialAction: TokenSequenceGenerator {
  case noAction
  case restrict
  case cascade
  case setNull(OptionalColumnList)
  case setDefault(OptionalColumnList)

  public static let setNull: ReferentialAction = .setNull(nil)

  public static let setDefault: ReferentialAction = .setDefault(nil)

  public var tokens: JoinedTokenSequence {
    switch self {
    case .noAction:
      return JoinedTokenSequence(SingleToken.no, SingleToken.action)
    case .restrict:
      return JoinedTokenSequence(SingleToken.restrict)
    case .cascade:
      return JoinedTokenSequence(SingleToken.cascade)
    case .setNull(let list):
      return JoinedTokenSequence(SingleToken.set, SingleToken.null, list)
    case .setDefault(let list):
      return JoinedTokenSequence(SingleToken.set, SingleToken.default, list)
    }
  }
}

/// A set of `ReferentialAction`s. Described as `key_actions` in "gram.y".
public struct ReferentialActionSet: TokenSequenceGenerator {
  public class Action: TokenSequenceGenerator, @unchecked Sendable {
    public let action: ReferentialAction

    fileprivate init(_ action: ReferentialAction) {
      self.action = action
    }

    public var tokens: JoinedTokenSequence { fatalError("Must be overridden.") }

    /// `key_delete` in "gram.y".
    public final class OnDelete: Action, @unchecked Sendable {
      public override var tokens: JoinedTokenSequence {
        return JoinedTokenSequence(SingleToken.on, SingleToken.delete, action)
      }
    }

    /// `key_update` in "gram.y".
    public final class OnUpdate: Action, @unchecked Sendable {
      public override var tokens: JoinedTokenSequence {
        return JoinedTokenSequence(SingleToken.on, SingleToken.update, action)
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

  public var tokens: JoinedTokenSequence {
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
