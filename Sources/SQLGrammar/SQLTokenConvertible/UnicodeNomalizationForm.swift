/* *************************************************************************************************
 UnicodeNormalizationForm.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A normalization form for Unicode text that is described as `unicode_normal_form` in "gram.y".
public enum UnicodeNormalizationForm: LosslessTokenConvertible {
  /// NFC
  case nfc

  /// NFD
  case nfd

  /// NFKC
  case nfkc

  /// NFKD
  case nfkd

  public var token: SQLToken {
    switch self {
    case .nfc:
      return .nfc
    case .nfd:
      return .nfd
    case .nfkc:
      return .nfkc
    case .nfkd:
      return .nfkd
    }
  }

  public init?(_ token: SQLToken) {
    switch token {
    case .nfc:
      self = .nfc
    case .nfd:
      self = .nfd
    case .nfkc:
      self = .nfkc
    case .nfkd:
      self = .nfkd
    default:
      return nil
    }
  }
}
