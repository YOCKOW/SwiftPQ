/* *************************************************************************************************
 RawParseMode.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

private class ModeSymbol: Token {
  static let typeName: ModeSymbol = .init(rawValue: "MODE_TYPE_NAME")
  static let plpgSQLExpression: ModeSymbol = .init(rawValue: "MODE_PLPGSQL_EXPR")
  static let plpgSQLAssignment1: ModeSymbol = .init(rawValue: "MODE_PLPGSQL_ASSIGN1")
  static let plpgSQLAssignment2: ModeSymbol = .init(rawValue: "MODE_PLPGSQL_ASSIGN2")
  static let plpgSQLAssignment3: ModeSymbol = .init(rawValue: "MODE_PLPGSQL_ASSIGN3")
}

private extension SingleToken {
  private init(_ mode: ModeSymbol) {
    self.init(mode as Token)
  }

  static let modeTypeName: SingleToken = .init(.typeName)
  static let modePLpgSQLExpression: SingleToken = .init(.plpgSQLExpression)
  static let modePLpgSQLAssignment1: SingleToken = .init(.plpgSQLAssignment1)
  static let modePLpgSQLAssignment2: SingleToken = .init(.plpgSQLAssignment2)
  static let modePLpgSQLAssignment3: SingleToken = .init(.plpgSQLAssignment3)
}


/// Corresponding type to an enum [`RawParseMode`](https://doxygen.postgresql.org/parser_8h.html#a07cc1510116b0047dad7ba4f1fd23a41)
/// defined in PostgreSQL's "parser.h".
/// This is described as `parse_toplevel` in "gram.y".
public enum RawParseMode: TokenSequenceGenerator {
  case `default`(StatementList)
  case typeName(TypeName)
  case plpgSQLExpression(PLpgSQLExpression)
  case plpgSQLAssignment1(PLpgSQLAssignmentStatement)
  case plpgSQLAssignment2(PLpgSQLAssignmentStatement)
  case plpgSQLAssignment3(PLpgSQLAssignmentStatement)

  public var tokens: JoinedSQLTokenSequence {
    switch self {
    case .default(let statementList):
      return statementList.tokens
    case .typeName(let typeName):
      return JoinedSQLTokenSequence(SingleToken.modeTypeName, typeName)
    case .plpgSQLExpression(let expr):
      return JoinedSQLTokenSequence(SingleToken.modePLpgSQLExpression, expr)
    case .plpgSQLAssignment1(let stmt):
      return JoinedSQLTokenSequence(SingleToken.modePLpgSQLAssignment1, stmt)
    case .plpgSQLAssignment2(let stmt):
      return JoinedSQLTokenSequence(SingleToken.modePLpgSQLAssignment2, stmt)
    case .plpgSQLAssignment3(let stmt):
      return JoinedSQLTokenSequence(SingleToken.modePLpgSQLAssignment3, stmt)
    }
  }
}


