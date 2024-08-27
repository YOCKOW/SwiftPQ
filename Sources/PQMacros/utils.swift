/* *************************************************************************************************
 utils.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import SwiftSyntax
import SystemPackage

private let _thisFilePath = FilePath(#filePath)
internal let macroModuleDirectoryPath = _thisFilePath.removingLastComponent()
internal let sourcesDirectoryPath = macroModuleDirectoryPath.removingLastComponent()
internal let repositoryDirectoryPath = sourcesDirectoryPath.removingLastComponent()
internal let postgresBranchFilePath = repositoryDirectoryPath.appending(".postgres-branch")
internal let assetsDirectoryPath = repositoryDirectoryPath.appending("assets")
internal let pgTypesDirectoryPath = assetsDirectoryPath.appending("pg-types")
internal var postgresBranch: String {
  get throws {
    enum __Postgres { static var branch: String? = nil }
    guard let branch = __Postgres.branch else {
      let fd = try! FileDescriptor.open(postgresBranchFilePath, .readOnly)
      let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1024, alignment: 8)
      defer { buffer.deallocate() }
      try fd.closeAfter {
        let _ = try fd.read(into: buffer)
        let branch = String(cString: buffer.bindMemory(to: CChar.self).baseAddress!)._trimmed
        __Postgres.branch = String(branch)
      }
      return __Postgres.branch!
    }
    return branch
  }
}
internal var pgTypeJSONFilePath: FilePath {
  get throws {
    return pgTypesDirectoryPath.appending("pg_type.\(try postgresBranch).json")
  }
}

extension String {
  var _trimmed: Substring {
    guard let firstIndex = self.firstIndex(where: { !$0.isWhitespace && !$0.isNewline }),
          let lastIndex = self.lastIndex(where: { !$0.isWhitespace && !$0.isNewline }) else {
      return ""
    }
    return self[firstIndex...lastIndex]
  }
}

extension FreestandingMacroExpansionSyntax {
#if compiler(<5.10)
  internal var arguments: LabeledExprSyntax {
    return node.argumentList
  }
#endif
}
