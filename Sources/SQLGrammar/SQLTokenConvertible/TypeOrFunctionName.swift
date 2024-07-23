/* *************************************************************************************************
 TypeOrFunctionName.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A name available for type or function. Described as `type_function_name` in "gram.y".
internal struct TypeOrFunctionName: LosslessTokenConvertible {
  let token: SQLToken

  init?(_ token: SQLToken) {
    switch token {
    case is SQLToken.Identifier:
      self.token = token
    case let keyword as SQLToken.Keyword where (
      keyword.isUnreserved || keyword.isAvailableForTypeOrFunctionName
    ):
      self.token = token
    default:
      return nil
    }
  }
}
