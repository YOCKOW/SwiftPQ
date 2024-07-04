/* *************************************************************************************************
 RowExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An expression that represents a row. It is described as `row` in "gram.y".
public struct RowExpression: Expression {
  private enum _Constructor {
    case explicit(RowConstructorExpression)
    case implicit(ImplicitRowConstructorExpression)
  }

  private let _constructor: _Constructor

  public var tokens: JoinedSQLTokenSequence {
    switch _constructor {
    case .explicit(let expr):
      return expr.tokens
    case .implicit(let expr):
      return expr.tokens.tokens
    }
  }

  public init(_ constructor: RowConstructorExpression) {
    self._constructor = .explicit(constructor)
  }

  public init(_ constructor: ImplicitRowConstructorExpression) {
    self._constructor = .implicit(constructor)
  }

  /// Creates a new `row` expression where columns are defined by `fields`.
  ///
  /// - Parameters:
  ///   - explicitDeclaration: Force to include `ROW` keyword in the sequence. (`ROW` keyword is
  ///                          added when the number of `fields` is less than 2 even if this value
  ///                          is `false`.)
  public init(explicitDeclaration: Bool = false, fields: Array<any GeneralExpression>) {
    let explicit = explicitDeclaration || fields.count < 2
    if explicit {
      self.init(
        RowConstructorExpression(
          fields: NonEmptyList(items: fields).map({ GeneralExpressionList($0) })
        )
      )
    } else {
      let lastField = fields.last!
      let prefixFields = GeneralExpressionList(NonEmptyList(items: fields.dropLast())!)
      self.init(ImplicitRowConstructorExpression(prefixFields: prefixFields, lastField: lastField))
    }
  }

  @inlinable
  public init() {
    self.init(explicitDeclaration: true, fields: [])
  }
}

extension RowExpression: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = (any GeneralExpression)

  @inlinable
  public init(arrayLiteral elements: (any GeneralExpression)...) {
    self.init(fields: elements)
  }
}
