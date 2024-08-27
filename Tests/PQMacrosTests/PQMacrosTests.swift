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
  "bool": BooleanMacro.self,
  "const": ConstantExpressionMacro.self,
  "FALSE": BooleanMacro.self,
  "param": PositionalParameterMacro.self,
  "paramExpr": PositionalParameterMacro.self,
  "TIMESTAMP": ConstantTypeCastStringLiteralSyntaxMacro.self,
  "TIMESTAMPTZ": ConstantTypeCastStringLiteralSyntaxMacro.self,
  "TRUE": BooleanMacro.self,
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
    let infoFromJSON = try JSONDecoder().decode(PGTypeInfo.self, from: Data(json.utf8))
    XCTAssertEqual(infoFromJSON.oid, 16)
    XCTAssertEqual(infoFromJSON.typeName, "bool")

    let dict = [
      "array_type_oid":"1002",
      "descr":"single character",
      "oid":"18",
      "typalign":"c",
      "typbyval":"t",
      "typcategory":"Z",
      "typinput":"charin",
      "typlen":"1",
      "typname":"char",
      "typoutput":"charout",
      "typreceive":"charrecv",
      "typsend":"charsend",
    ]
    let infoFromDict = try PGTypeInfo(dict)
    XCTAssertEqual(infoFromDict.oid, 18)
    XCTAssertEqual(infoFromDict.typeName, "char")
  }

  func test_manager() throws {
    let manager = PGTypeManager.default
    XCTAssertEqual(try manager.list.oidToInfo[16]?.typeName, "bool")
    XCTAssertEqual(try manager.list.nameToInfo["float8"]?.typeByValue, .other("FLOAT8PASSBYVAL"))
  }
}

final class PQMacrosTests: XCTestCase {
  func test_bool() {
    #if canImport(PQMacros)
    let trueSource = "BooleanConstantExpression.true"
    let falseSource = "BooleanConstantExpression.false"
    assertMacroExpansion("#bool(true)", expandedSource: trueSource, macros: testMacros)
    assertMacroExpansion("#bool(false)", expandedSource: falseSource, macros: testMacros)
    assertMacroExpansion("#TRUE", expandedSource: trueSource, macros: testMacros)
    assertMacroExpansion("#FALSE", expandedSource: falseSource, macros: testMacros)
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

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
      #"#const(Int(-1))"#,
      expandedSource: "UnaryPrefixMinusOperatorInvocation(UnsignedIntegerConstantExpression(1))",
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(-123.45)"#,
      expandedSource: #"UnaryPrefixMinusOperatorInvocation(UnsignedFloatConstantExpression(123.45))"#,
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(true)"#,
      expandedSource: "BooleanConstantExpression.true",
      macros: testMacros
    )
    assertMacroExpansion(
      #"#const(false)"#,
      expandedSource: "BooleanConstantExpression.false",
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func test_constTypeCastStringLiteralSyntax() {
    #if canImport(PQMacros)
    assertMacroExpansion(
      ##"#TIMESTAMP("2004-10-19 10:23:54")"##,
      expandedSource: """
      ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
        constantTypeName: .timestamp,
        string: "2004-10-19 10:23:54"
      )
      """,
      macros: testMacros
    )
    assertMacroExpansion(
      ##"#TIMESTAMPTZ("2004-10-19 10:23:54+09")"##,
      expandedSource: """
      ConstantTypeCastStringLiteralSyntax<ConstantDateTimeTypeName>(
        constantTypeName: .timestamp(withTimeZone: true),
        string: "2004-10-19 10:23:54+09"
      )
      """,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func test_param() {
    #if canImport(PQMacros)
    assertMacroExpansion(
      #"#param(123)"#,
      expandedSource: "Token.PositionalParameter(123)",
      macros: testMacros
    )
    assertMacroExpansion(
      #"#paramExpr(123)"#,
      expandedSource: "Token.PositionalParameter(123).asExpression",
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
