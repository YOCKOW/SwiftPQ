/* *************************************************************************************************
 ConstraintOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An option to control whether or not the constraint can be deferred.
public enum DeferrableConstraintOption {
  case deferrable
  case notDeferrable

  @inlinable
  public var tableConstraintAttributeElement: TableConstraintAttributeElement {
    switch self {
    case .deferrable:
      return .deferrable
    case .notDeferrable:
      return .notDeferrable
    }
  }
}

/// The default time to check the constraint
public enum ConstraintCheckingTimeOption {
  case initiallyDeferred
  case initiallyImmediate

  @inlinable
  public var tableConstraintAttributeElement: TableConstraintAttributeElement {
    switch self {
    case .initiallyDeferred:
      return .initiallyDeferred
    case .initiallyImmediate:
      return .initiallyImmediate
    }
  }
}
