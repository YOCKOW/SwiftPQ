/* *************************************************************************************************
 DropStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing "DROP" statement that is described as `DropStmt` in "gram.y".
public protocol DropStatement: Statement {}

/// One of "DROP" statement whose object is an `ObjectTypeAnyName`, that is described as
/// '`DROP object_type_any_name IF_P EXISTS any_name_list opt_drop_behavior`' or
/// '`DROP object_type_any_name any_name_list opt_drop_behavior`' in "gram.y".
public protocol DropObjectTypeAnyName: DropStatement {
  var object: ObjectTypeAnyName { get }
  var ifExists: Bool { get }
  var names: AnyNameList { get }
  var behavior: DropBehavior? { get }
}
