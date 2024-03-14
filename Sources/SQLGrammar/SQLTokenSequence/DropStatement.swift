/* *************************************************************************************************
 DropStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing "DROP" statement that is described as `DropStmt` in "gram.y".
public protocol DropStatement: Statement {}

/// One of "DROP" statement whose object is an `ObjectTypeAnyName`.
///
/// Represented statement is described as one of below  in "gram.y":
/// - `DROP object_type_any_name IF_P EXISTS any_name_list opt_drop_behavior`
/// - `DROP object_type_any_name any_name_list opt_drop_behavior`'
public protocol DropObjectTypeAnyName: DropStatement {
  var object: ObjectTypeAnyName { get }
  var ifExists: Bool { get }
  var names: AnyNameList { get }
  var behavior: DropBehavior? { get }
}

extension DropObjectTypeAnyName where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(
      SingleToken(.drop),
      object,
      ifExists ? ifExistsSegment : nil,
      names,
      behavior.map({ SingleToken($0) })
    )
  }
}

/// Represents "DROP TABLE" statement.
public struct DropTable: DropObjectTypeAnyName {
  public let object: ObjectTypeAnyName = .table

  public let ifExists: Bool

  public let names: AnyNameList

  public let behavior: DropBehavior?

  public init(ifExists: Bool = false, names: AnyNameList, behavior: DropBehavior? = nil) {
    self.ifExists = ifExists
    self.names = names
    self.behavior = behavior
  }
}
