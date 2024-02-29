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
  "binOp": BinaryInfixOperatorInvocationMacro.self,
]
#endif

final class PQMacrosTests: XCTestCase {
  func test_binOp() throws {
    #if canImport(PQMacros)
    assertMacroExpansion(
      """
      #binOp("a" + "'b'")
      """,
      expandedSource: """
      BinaryInfixOperatorInvocation(SingleToken.identifier("a"), .plus, SingleToken.string("b"))
      """,
      macros: testMacros
    )
    assertMacroExpansion(
      """
      #binOp(1 < 2.3)
      """,
      expandedSource: """
      BinaryInfixOperatorInvocation(SingleToken.integer(1), .lessThan, SingleToken.float(2.3))
      """,
      macros: testMacros
    )
    assertMacroExpansion(
      """
      #binOp("n", "=", 2)
      """,
      expandedSource: """
      BinaryInfixOperatorInvocation(SingleToken.identifier("n"), .equalTo, SingleToken.integer(2))
      """,
      macros: testMacros
    )
    assertMacroExpansion(
      """
      #binOp("n", "||||||||||", 2)
      """,
      expandedSource: """
      BinaryInfixOperatorInvocation(SingleToken.identifier("n"), .single(.init("||||||||||")), SingleToken.integer(2))
      """,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
