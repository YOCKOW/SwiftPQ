/* *************************************************************************************************
 XMLPassingArgument.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// Tokens to be passed as an argument described as `xmlexists_argument` in "gram.y".
public struct XMLPassingArgument: TokenSequenceGenerator {
  /// A mechanism that apply when passing an XML argument from SQL
  /// to an XML function or receiving a result.
  /// It is described as`xml_passing_mech` in "gram.y".
  ///
  /// - Note: Only BY VALUE Passing Mechanism Is Supported in PostgreSQL.
  public enum Mechanism: Segment {
    case byReference
    case byValue

    private static let _byReferenceTokens: [SQLToken] = [.by, .ref]
    private static let _byValueTokens: [SQLToken] = [.by, .value]

    public var tokens: Array<SQLToken> {
      switch self {
      case .byReference:
        return Mechanism._byReferenceTokens
      case .byValue:
        return Mechanism._byValueTokens
      }
    }
  }

  public let defaultMechanism: Mechanism?

  public let xml: any ProductionExpression

  public let overriddenMechanism: Mechanism?

  public var tokens: JoinedSQLTokenSequence {
    return .compacting([
      SingleToken(.passing),
      defaultMechanism,
      xml,
      overriddenMechanism,
    ] as [(any TokenSequenceGenerator)?] )
  }

  public init(
    defaultMechanism: Mechanism? = nil,
    xml: any ProductionExpression,
    overriddenMechanism: Mechanism? = nil
  ) {
    self.defaultMechanism = defaultMechanism
    self.xml = xml
    self.overriddenMechanism = overriddenMechanism
  }

  public init(
    defaultMechanism: Mechanism? = nil,
    xml: StringConstantExpression,
    overriddenMechanism: Mechanism? = nil
  ) {
    self.defaultMechanism = defaultMechanism
    self.xml = xml
    self.overriddenMechanism = overriddenMechanism
  }
}
