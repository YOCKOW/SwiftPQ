/* *************************************************************************************************
 If(Not)Exists.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing only `IF EXISTS`.
public final class IfExists: Segment {
  public let tokens: [SQLToken] = [.if, .exists]
  public static let ifExists: IfExists = .init()
}
public let ifExistsSegment: IfExists = .ifExists

/// A type representing only `IF NOT EXISTS`.
public final class IfNotExists: Segment {
  public let tokens: [SQLToken] = [.if, .not, .exists]
  public static let ifNotExists: IfNotExists = .init()
}
public let ifNotExistsSegment: IfNotExists = .ifNotExists
