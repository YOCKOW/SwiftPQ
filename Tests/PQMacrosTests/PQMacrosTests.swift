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

let testMacros: [String: Macro.Type] = [:]
#endif

final class PQMacrosTests: XCTestCase {
}
