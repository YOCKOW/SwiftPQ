/* *************************************************************************************************
 TypeOrFunctionName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A name available for type or function. Described as `type_function_name` in "gram.y".
internal struct TypeOrFunctionName: LosslessTokenConvertible, Sendable {
  let token: Token

  init?(_ token: Token) {
    switch token {
    case is Token.Identifier:
      self.token = token
    case let keyword as Token.Keyword where (
      keyword.isUnreserved || keyword.isAvailableForTypeOrFunctionName
    ):
      self.token = token
    default:
      return nil
    }
  }
}
