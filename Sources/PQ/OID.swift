/* *************************************************************************************************
 OID.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import CLibPQ

@attached(member, names: arbitrary)
private macro _ExpandOIDs() = #externalMacro(module: "PQMacros", type: "OIDExpander")

/// Object identifier that corresponds to a primary key used internally by PostgreSQL.
///
/// See Official Documentation [§8.19. Object Identifier Types](https://www.postgresql.org/docs/current/datatype-oid.html).
@_ExpandOIDs
public struct OID: RawRepresentable, Equatable {
  public typealias RawValue = CLibPQ.Oid

  public let rawValue: RawValue

  public init(rawValue: RawValue) {
    self.rawValue = rawValue
  }
}
