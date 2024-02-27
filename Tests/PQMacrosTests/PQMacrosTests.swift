/* *************************************************************************************************
 PQMacrosTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PQMacros)
import PQMacros

let testMacros: [String: Macro.Type] = [
  "stringify": StringifyMacro.self,
]
#endif

final class PQMacrosTests: XCTestCase {
  func testMacro() throws {
    #if canImport(PQMacros)
    assertMacroExpansion(
      """
      #stringify(a + b)
      """,
      expandedSource: """
      (a + b, "a + b")
      """,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testMacroWithStringLiteral() throws {
    #if canImport(PQMacros)
    assertMacroExpansion(
      #"""
      #stringify("Hello, \(name)")
      """#,
      expandedSource: #"""
      ("Hello, \(name)", #""Hello, \(name)""#)
      """#,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
