/* *************************************************************************************************
 String+SwiftSyntax.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@_spi(RawSyntax) import SwiftSyntax

internal extension String {
  var _isSwiftKeyword: Bool {
    mutating get {
      return self.withSyntaxText {
        return SwiftSyntax.Keyword($0) != nil
      }
    }
  }

  var _swiftIdentifier: IdentifierPatternSyntax {
    let prefix = self.prefix(while: { $0 == "_" })
    let prefixCount = prefix.count

    let idSource = self.dropFirst(prefixCount)

    let splitted = idSource.split(whereSeparator: {
      guard $0.isASCII else { fatalError("Non-ASCII character is contained.") }
      return !$0.isLetter && !$0.isNumber
    })
    guard let first = splitted.first else {
      fatalError("Empty keyword?!")
    }
    var idDesc = String(prefix)
    idDesc += first.lowercased()
    for word in splitted.dropFirst() {
      idDesc += String(word).capitalized
    }
    if idDesc._isSwiftKeyword {
      idDesc = "`\(idDesc)`"
    }
    return .init(identifier: TokenSyntax(.identifier(idDesc), presence: .present))
  }
}
