/* *************************************************************************************************
 Is(Not)DocumentExpression.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private final class _IsDocument: Segment {
  let tokens: Array<Token> = [.is, .document]
  private init() {}
  static let isDocument: _IsDocument = .init()
}

private final class _IsNotDocument: Segment {
  let tokens: Array<Token> = [.is, .not, .document]
  private init() {}
  static let isNotDocument: _IsNotDocument = .init()
}

/// Representation of `IS DOCUMENT` expression.
public struct IsDocumentExpression<XMLValue>: Expression where XMLValue: Expression {
  public let value: XMLValue

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(value, _IsDocument.isDocument)
  }

  public init(_ value: XMLValue) {
    self.value = value
  }
}
extension IsDocumentExpression: RecursiveExpression where XMLValue: RecursiveExpression {}
extension IsDocumentExpression: GeneralExpression where XMLValue: GeneralExpression {}
extension IsDocumentExpression: RestrictedExpression where XMLValue: RestrictedExpression {}
extension RecursiveExpression {
  public var isDocumentExpression: IsDocumentExpression<Self> {
    return .init(self)
  }
}

/// Representation of `IS NOT DOCUMENT` expression.
public struct IsNotDocumentExpression<XMLValue>: Expression where XMLValue: Expression {
  public let value: XMLValue

  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence(value, _IsNotDocument.isNotDocument)
  }

  public init(_ value: XMLValue) {
    self.value = value
  }
}
extension IsNotDocumentExpression: RecursiveExpression where XMLValue: RecursiveExpression {}
extension IsNotDocumentExpression: GeneralExpression where XMLValue: GeneralExpression {}
extension IsNotDocumentExpression: RestrictedExpression where XMLValue: RestrictedExpression {}
extension RecursiveExpression {
  public var isNotDocumentExpression: IsNotDocumentExpression<Self> {
    return .init(self)
  }
}

