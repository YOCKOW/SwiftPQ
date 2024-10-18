/* *************************************************************************************************
 utils.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax

extension FreestandingMacroExpansionSyntax {
#if compiler(<5.10)
  internal var arguments: LabeledExprSyntax {
    return node.argumentList
  }
#endif
}
