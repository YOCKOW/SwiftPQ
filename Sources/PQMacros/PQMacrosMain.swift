/* *************************************************************************************************
 PQMacrosMain.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PQMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    BinaryInfixOperatorInvocationMacro.self,
    BinaryInfixOperatorInvocationShortcutMacro.self,
    StaticKeywordExpander.self,
    WellknownOperatorsExpander.self,
  ]
}
