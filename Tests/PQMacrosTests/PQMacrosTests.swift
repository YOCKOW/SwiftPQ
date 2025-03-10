/* *************************************************************************************************
 PQMacrosTests.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PQMacros)
import PQMacros

let testMacros: [String: Macro.Type] = [
  "bool": BooleanMacro.self,
  "const": ConstantExpressionMacro.self,
  "DATE": TypeCastStringLiteralSyntaxMacro.self,
  "FALSE": BooleanMacro.self,
  "INTERVAL": TypeCastStringLiteralSyntaxMacro.self,
  "param": PositionalParameterMacro.self,
  "paramExpr": PositionalParameterMacro.self,
  "TIMESTAMP": TypeCastStringLiteralSyntaxMacro.self,
  "TIMESTAMPTZ": TypeCastStringLiteralSyntaxMacro.self,
  "TRUE": BooleanMacro.self,
]
#endif

#if swift(>=6) && canImport(Testing)
import Testing

@Suite final class PGTypeManagerTests {
  @Test func test_typeInfo() throws {
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
    #expect(infoFromJSON.oid == 16)
    #expect(infoFromJSON.typeName == "bool")

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
    #expect(infoFromDict.oid == 18)
    #expect(infoFromDict.typeName == "char")
  }

  @Test func test_manager() throws {
    let manager = PGTypeManager.default
    #expect(try manager.list.oidToInfo[16]?.typeName == "bool")
    #expect(try manager.list.nameToInfo["float8"]?.typeByValue == .other("FLOAT8PASSBYVAL"))
  }
}

@Suite final class PQMacrosTests {
  @Test func test_bool() {
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

  @Test func test_const() {
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

  @Test func test_TypeCastStringLiteralSyntax() {
    #if canImport(PQMacros)
    assertMacroExpansion(
      ##"#DATE("2024-08-27")"##,
      expandedSource: """
      GenericTypeCastStringLiteralSyntax(typeName: TypeName.date, string: "2024-08-27")!
      """,
      macros: testMacros
    )
    assertMacroExpansion(
      ##"#INTERVAL("3 years 3 mons 700 days 133:17:36.789")"##,
      expandedSource: """
      ConstantIntervalTypeCastStringLiteralSyntax(string: "3 years 3 mons 700 days 133:17:36.789")!
      """,
      macros: testMacros
    )
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

  @Test func test_param() {
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

#else
import XCTest

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

  func test_TypeCastStringLiteralSyntax() {
#if canImport(PQMacros)
    assertMacroExpansion(
      ##"#DATE("2024-08-27")"##,
      expandedSource: """
      GenericTypeCastStringLiteralSyntax(typeName: TypeName.date, string: "2024-08-27")!
      """,
      macros: testMacros
    )
    assertMacroExpansion(
      ##"#INTERVAL("3 years 3 mons 700 days 133:17:36.789")"##,
      expandedSource: """
      ConstantIntervalTypeCastStringLiteralSyntax(string: "3 years 3 mons 700 days 133:17:36.789")!
      """,
      macros: testMacros
    )
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
#endif
