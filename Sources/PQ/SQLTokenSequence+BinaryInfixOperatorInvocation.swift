/* *************************************************************************************************
 SQLTokenSequence+BinaryInfixOperatorInvocation.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// TODO: Use macro?

extension SQLTokenSequence {
  /// Create an invocation sequence of `self / right`.
  public func divide(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .minus, rhs)
  }

  /// Create an invocation sequence of `self / right`.
  public func divide(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self = right`.
  public func equalTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .equalTo, rhs)
  }

  /// Create an invocation sequence of `self = right`.
  public func equalTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return equalTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self > right`.
  public func greaterThan(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .greaterThan, rhs)
  }

  /// Create an invocation sequence of `self > right`.
  public func greaterThan(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return greaterThan(rhs.asSequence)
  }

  /// Create an invocation sequence of `self >= right`.
  public func greaterThanOrEqualTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .greaterThanOrEqualTo, rhs)
  }

  /// Create an invocation sequence of `self >= right`.
  public func greaterThanOrEqualTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return greaterThanOrEqualTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self < right`.
  public func lessThan(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .lessThan, rhs)
  }

  /// Create an invocation sequence of `self < right`.
  public func lessThan(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return lessThan(rhs.asSequence)
  }

  /// Create an invocation sequence of `self <= right`.
  public func lessThanOrEqualTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .lessThanOrEqualTo, rhs)
  }

  /// Create an invocation sequence of `self <= right`.
  public func lessThanOrEqualTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return lessThanOrEqualTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self - right`.
  public func minus(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .minus, rhs)
  }

  /// Create an invocation sequence of `self - right`.
  public func minus(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self % right`.
  public func modulo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .minus, rhs)
  }

  /// Create an invocation sequence of `self % right`.
  public func modulo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self * right`.
  public func multiply(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .minus, rhs)
  }

  /// Create an invocation sequence of `self * right`.
  public func multiply(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self <> right`.
  public func notEqualTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .notEqualTo, rhs)
  }

  /// Create an invocation sequence of `self <> right`.
  public func notEqualTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return notEqualTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self + right`.
  public func plus(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return .init(self, .plus, rhs)
  }

  /// Create an invocation sequence of `self + right`.
  public func plus(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return plus(rhs.asSequence)
  }
}

extension SQLToken {
  /// Create an invocation sequence of `self / right`.
  public func divide(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.divide(rhs)
  }

  /// Create an invocation sequence of `self / right`.
  public func divide(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return divide(rhs.asSequence)
  }

  /// Create an invocation sequence of `self = right`.
  public func equalTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.equalTo(rhs)
  }

  /// Create an invocation sequence of `self = right`.
  public func equalTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return equalTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self > right`.
  public func greaterThan(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.greaterThan(rhs)
  }

  /// Create an invocation sequence of `self > right`.
  public func greaterThan(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return greaterThan(rhs.asSequence)
  }

  /// Create an invocation sequence of `self >= right`.
  public func greaterThanOrEqualTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.greaterThanOrEqualTo(rhs)
  }

  /// Create an invocation sequence of `self >= right`.
  public func greaterThanOrEqualTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return greaterThanOrEqualTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self < right`.
  public func lessThan(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.lessThan(rhs)
  }

  /// Create an invocation sequence of `self < right`.
  public func lessThan(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return lessThan(rhs.asSequence)
  }

  /// Create an invocation sequence of `self <= right`.
  public func lessThanOrEqualTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.lessThanOrEqualTo(rhs)
  }

  /// Create an invocation sequence of `self <= right`.
  public func lessThanOrEqualTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return lessThanOrEqualTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self - right`.
  public func minus(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.minus(rhs)
  }

  /// Create an invocation sequence of `self - right`.
  public func minus(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self % right`.
  public func modulo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.modulo(rhs)
  }

  /// Create an invocation sequence of `self % right`.
  public func modulo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self * right`.
  public func multiply(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.multiply(rhs)
  }

  /// Create an invocation sequence of `self * right`.
  public func multiply(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return minus(rhs.asSequence)
  }

  /// Create an invocation sequence of `self <> right`.
  public func notEqualTo(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.notEqualTo(rhs)
  }

  /// Create an invocation sequence of `self <> right`.
  public func notEqualTo(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return notEqualTo(rhs.asSequence)
  }

  /// Create an invocation sequence of `self + right`.
  public func plus(_ rhs: any SQLTokenSequence) -> BinaryInfixOperatorInvocation {
    return self.asSequence.plus(rhs)
  }

  /// Create an invocation sequence of `self + right`.
  public func plus(_ rhs: SQLToken) -> BinaryInfixOperatorInvocation {
    return plus(rhs.asSequence)
  }
}
