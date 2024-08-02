/* *************************************************************************************************
 PQMacrosTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CPostgreSQL
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PQMacros)
import PQMacros

let testMacros: [String: Macro.Type] = [
  "const": ConstantExpressionMacro.self,
]
#endif

final class PGTypeManagerTests: XCTestCase {
  func test_typeInfo() throws {
    let json = """
    {
      "array_type_oid": "1000",
      "descr": "boolean, 'true'/'false'",
      "oid": "16",
      "typalign": "c",
      "typbyval": "t",
      "typcategory": "B",
      "typinput": "boolin",
      "typispreferred": "t",
      "typlen": "1",
      "typname": "bool",
      "typoutput": "boolout",
      "typreceive": "boolrecv",
      "typsend": "boolsend"
    }
    """
    let info = try JSONDecoder().decode(PGTypeInfo.self, from: Data(json.utf8))
    XCTAssertEqual(info.oid, 16)
    XCTAssertEqual(info.typeName, "bool")
  }

  func test_manager() throws {
    let manager = PGTypeManager.default
    XCTAssertEqual(try manager.list.oidToInfo[16]?.typeName, "bool")
    XCTAssertEqual(try manager.list.nameToInfo["float8"]?.typeByValue, _SwiftPQ_get_FLOAT8PASSBYVAL())
  }
}

final class PQMacrosTests: XCTestCase {
  func test_const() {
    #if canImport(PQMacros)
    assertMacroExpansion(
      #"#const("string constant")"#,
      expandedSource: #"StringConstantExpression("string constant")"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(123)"#,
      expandedSource: #"UnsignedIntegerConstantExpression(123)"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(123.45)"#,
      expandedSource: #"UnsignedFloatConstantExpression(123.45)"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(+123)"#,
      expandedSource: #"UnaryPrefixPlusOperatorInvocation(UnsignedIntegerConstantExpression(123))"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(+123.45)"#,
      expandedSource: #"UnaryPrefixPlusOperatorInvocation(UnsignedFloatConstantExpression(123.45))"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(-123)"#,
      expandedSource: #"UnaryPrefixMinusOperatorInvocation(UnsignedIntegerConstantExpression(123))"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(-123.45)"#,
      expandedSource: #"UnaryPrefixMinusOperatorInvocation(UnsignedFloatConstantExpression(123.45))"#,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
