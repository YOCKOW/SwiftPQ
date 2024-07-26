/* *************************************************************************************************
 Macros.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@attached(member, names: arbitrary)
internal macro _ExpandStaticKeywords() = #externalMacro(module: "PQMacros", type: "StaticKeywordExpander")

@attached(member, names: arbitrary)
internal macro _ExpandWellknownOperators() = #externalMacro(module: "PQMacros", type: "WellknownOperatorsExpander")
