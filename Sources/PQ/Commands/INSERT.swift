/* *************************************************************************************************
 INSERT.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public enum ConflictAction: SQLTokenSequence {
  public enum UpdateAction: SQLTokenSequence {
    public enum Value: SQLTokenSequence {
      case `default`
      case expression(any SQLTokenSequence)

      public var tokens: [SQLToken] {
        switch self {
        case .default:
          return [.default]
        case .expression(let seq):
          return seq.tokens
        }
      }
    }

    public enum Values: SQLTokenSequence {
      case values([Value])
//      case select(Select)

      public var tokens: [SQLToken] {
        switch self {
        case .values(let values):
          var tokens: [SQLToken] = [.row, .leftParenthesis, .joiner]
          tokens.append(contentsOf: values.joinedByCommas())
          tokens.append(contentsOf: [.joiner, .rightParenthesis])
          return tokens
        }
      }
    }

    case singleColumn(ColumnName, value: Value)
    case multipleColumns([ColumnName], values: Values)

    public var tokens: [SQLToken] {
      switch self {
      case .singleColumn(let columnName, let value):
        return [columnName.token, SQLToken.Operator.equalTo] + value.tokens
      case .multipleColumns(let columnNames, let values):
        var tokens: [SQLToken] = [.leftParenthesis, .joiner]
        tokens.append(contentsOf: columnNames.map(\.token).joinedByCommas())
        tokens.append(contentsOf: [.joiner, .rightParenthesis, SQLToken.Operator.equalTo])
        tokens.append(contentsOf: values.tokens)
        return tokens
      }
    }
  }

  case doNothing
  case update([UpdateAction], where: (any SQLTokenSequence)? = nil)

  public var tokens: [SQLToken] {

    switch self {
    case .doNothing:
      return [.do, .nothing]
    case .update(let actions, let condition):
      var tokens: [SQLToken] = [.do, .update, .set]
      tokens.append(contentsOf: actions.joinedByCommas())
      condition.map { tokens.append(contentsOf: $0) }
      return tokens
    }
  }
}

/// A representation of `INSERT` command.
public struct Insert: SQLTokenSequence {
  public var tokens: [SQLToken] {
    return []
  }
}
