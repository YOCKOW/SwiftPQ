/* *************************************************************************************************
 OID.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ

/// Object identifier that corresponds to a primary key used internally by PostgreSQL.
///
/// See Official Documentation [§8.19. Object Identifier Types](https://www.postgresql.org/docs/current/datatype-oid.html).
public struct OID: RawRepresentable {
  public typealias RawValue = CLibPQ.Oid

  public let rawValue: RawValue

  public init(rawValue: RawValue) {
    self.rawValue = rawValue
  }
}
