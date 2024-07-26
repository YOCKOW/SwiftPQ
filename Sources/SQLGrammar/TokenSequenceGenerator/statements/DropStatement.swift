/* *************************************************************************************************
 DropStatement.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// A type representing "DROP" statement that is described as `DropStmt` in "gram.y".
public protocol DropStatement: Statement {
  associatedtype ItemTypeName: TokenSequenceGenerator
  associatedtype ItemNameList: TokenSequenceGenerator

  var itemType: ItemTypeName { get }
  var ifExists: Bool { get }
  var itemNames: ItemNameList { get }
  var behavior: DropBehavior? { get }
}

extension DropStatement where Self.Tokens == JoinedSQLTokenSequence {
  public var tokens: JoinedSQLTokenSequence {
    return JoinedSQLTokenSequence.compacting(
      SingleToken(.drop),
      itemType,
      ifExists ? ifExistsSegment : nil,
      itemNames,
      behavior.map({ SingleToken($0) })
    )
  }
}

/// One of "DROP" statement whose object is an `ObjectTypeAnyName`.
///
/// Represented statement is described as one of below  in "gram.y":
/// - `DROP object_type_any_name IF_P EXISTS any_name_list opt_drop_behavior`
/// - `DROP object_type_any_name any_name_list opt_drop_behavior`'
public protocol DropObjectTypeAnyNameStatement: 
  DropStatement where ItemTypeName == ObjectTypeAnyName,
                      ItemNameList == AnyNameList {
  var object: ObjectTypeAnyName { get }
  var ifExists: Bool { get }
  var names: AnyNameList { get }
  var behavior: DropBehavior? { get }
}

extension DropObjectTypeAnyNameStatement {
  public var itemType: ItemTypeName { return object }
  public var itemNames: ItemNameList { return names }
}

/// Represents "DROP TABLE" statement.
public struct DropTableStatement: DropObjectTypeAnyNameStatement {
  public let object: ObjectTypeAnyName = .table

  public let ifExists: Bool

  public let names: AnyNameList

  public let behavior: DropBehavior?

  public init(ifExists: Bool = false, names: AnyNameList, behavior: DropBehavior? = nil) {
    self.ifExists = ifExists
    self.names = names
    self.behavior = behavior
  }

  @inlinable
  public init?<C>(
    names: C,
    ifExists: Bool = false,
    behavior: DropBehavior? = nil
  ) where C: Collection, C.Element == TableName {
    guard let list = NonEmptyList<any AnyName>(items: names.map({ $0 as any AnyName })) else {
      return nil
    }
    self.init(ifExists: ifExists, names: AnyNameList(names: list), behavior: behavior)
  }

  @inlinable
  public init<T>(ifExists: Bool = false, name: T, behavior: DropBehavior? = nil) where T: AnyName {
    self.init(ifExists: ifExists, names: AnyNameList(names: [name]), behavior: behavior)
  }

  @inlinable
  public init(ifExists: Bool = false, name: TableName, behavior: DropBehavior? = nil) {
    self.init(ifExists: ifExists, names: AnyNameList(names: [name]), behavior: behavior)
  }
}
