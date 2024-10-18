/* *************************************************************************************************
 KeywordManager.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Dispatch
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

final class KeywordManager: @unchecked Sendable {
  static let defaultUnreservedKeywords: Set<String> = [
    "ABORT",
    "ABSENT",
    "ABSOLUTE",
    "ACCESS",
    "ACTION",
    "ADD",
    "ADMIN",
    "AFTER",
    "AGGREGATE",
    "ALSO",
    "ALTER",
    "ALWAYS",
    "ASENSITIVE",
    "ASSERTION",
    "ASSIGNMENT",
    "AT",
    "ATOMIC",
    "ATTACH",
    "ATTRIBUTE",
    "BACKWARD",
    "BEFORE",
    "BEGIN",
    "BREADTH",
    "BY",
    "CACHE",
    "CALL",
    "CALLED",
    "CASCADE",
    "CASCADED",
    "CATALOG",
    "CHAIN",
    "CHARACTERISTICS",
    "CHECKPOINT",
    "CLASS",
    "CLOSE",
    "CLUSTER",
    "COLUMNS",
    "COMMENT",
    "COMMENTS",
    "COMMIT",
    "COMMITTED",
    "COMPRESSION",
    "CONFIGURATION",
    "CONFLICT",
    "CONNECTION",
    "CONSTRAINTS",
    "CONTENT",
    "CONTINUE",
    "CONVERSION",
    "COPY",
    "COST",
    "CSV",
    "CUBE",
    "CURRENT",
    "CURSOR",
    "CYCLE",
    "DATA",
    "DATABASE",
    "DAY",
    "DEALLOCATE",
    "DECLARE",
    "DEFAULTS",
    "DEFERRED",
    "DEFINER",
    "DELETE",
    "DELIMITER",
    "DELIMITERS",
    "DEPENDS",
    "DEPTH",
    "DETACH",
    "DICTIONARY",
    "DISABLE",
    "DISCARD",
    "DOCUMENT",
    "DOMAIN",
    "DOUBLE",
    "DROP",
    "EACH",
    "ENABLE",
    "ENCODING",
    "ENCRYPTED",
    "ENUM",
    "ESCAPE",
    "EVENT",
    "EXCLUDE",
    "EXCLUDING",
    "EXCLUSIVE",
    "EXECUTE",
    "EXPLAIN",
    "EXPRESSION",
    "EXTENSION",
    "EXTERNAL",
    "FAMILY",
    "FILTER",
    "FINALIZE",
    "FIRST",
    "FOLLOWING",
    "FORCE",
    "FORMAT",
    "FORWARD",
    "FUNCTION",
    "FUNCTIONS",
    "GENERATED",
    "GLOBAL",
    "GRANTED",
    "GROUPS",
    "HANDLER",
    "HEADER",
    "HOLD",
    "HOUR",
    "IDENTITY",
    "IF",
    "IMMEDIATE",
    "IMMUTABLE",
    "IMPLICIT",
    "IMPORT",
    "INCLUDE",
    "INCLUDING",
    "INCREMENT",
    "INDENT",
    "INDEX",
    "INDEXES",
    "INHERIT",
    "INHERITS",
    "INLINE",
    "INPUT",
    "INSENSITIVE",
    "INSERT",
    "INSTEAD",
    "INVOKER",
    "ISOLATION",
    "JSON",
    "KEY",
    "KEYS",
    "LABEL",
    "LANGUAGE",
    "LARGE",
    "LAST",
    "LEAKPROOF",
    "LEVEL",
    "LISTEN",
    "LOAD",
    "LOCAL",
    "LOCATION",
    "LOCK",
    "LOCKED",
    "LOGGED",
    "MAPPING",
    "MATCH",
    "MATCHED",
    "MATERIALIZED",
    "MAXVALUE",
    "MERGE",
    "METHOD",
    "MINUTE",
    "MINVALUE",
    "MODE",
    "MONTH",
    "MOVE",
    "NAME",
    "NAMES",
    "NEW",
    "NEXT",
    "NFC",
    "NFD",
    "NFKC",
    "NFKD",
    "NO",
    "NORMALIZED",
    "NOTHING",
    "NOTIFY",
    "NOWAIT",
    "NULLS",
    "OBJECT",
    "OF",
    "OFF",
    "OIDS",
    "OLD",
    "OPERATOR",
    "OPTION",
    "OPTIONS",
    "ORDINALITY",
    "OTHERS",
    "OVER",
    "OVERRIDING",
    "OWNED",
    "OWNER",
    "PARALLEL",
    "PARAMETER",
    "PARSER",
    "PARTIAL",
    "PARTITION",
    "PASSING",
    "PASSWORD",
    "PLANS",
    "POLICY",
    "PRECEDING",
    "PREPARE",
    "PREPARED",
    "PRESERVE",
    "PRIOR",
    "PRIVILEGES",
    "PROCEDURAL",
    "PROCEDURE",
    "PROCEDURES",
    "PROGRAM",
    "PUBLICATION",
    "QUOTE",
    "RANGE",
    "READ",
    "REASSIGN",
    "RECHECK",
    "RECURSIVE",
    "REF",
    "REFERENCING",
    "REFRESH",
    "REINDEX",
    "RELATIVE",
    "RELEASE",
    "RENAME",
    "REPEATABLE",
    "REPLACE",
    "REPLICA",
    "RESET",
    "RESTART",
    "RESTRICT",
    "RETURN",
    "RETURNS",
    "REVOKE",
    "ROLE",
    "ROLLBACK",
    "ROLLUP",
    "ROUTINE",
    "ROUTINES",
    "ROWS",
    "RULE",
    "SAVEPOINT",
    "SCALAR",
    "SCHEMA",
    "SCHEMAS",
    "SCROLL",
    "SEARCH",
    "SECOND",
    "SECURITY",
    "SEQUENCE",
    "SEQUENCES",
    "SERIALIZABLE",
    "SERVER",
    "SESSION",
    "SET",
    "SETS",
    "SHARE",
    "SHOW",
    "SIMPLE",
    "SKIP",
    "SNAPSHOT",
    "SQL",
    "STABLE",
    "STANDALONE",
    "START",
    "STATEMENT",
    "STATISTICS",
    "STDIN",
    "STDOUT",
    "STORAGE",
    "STORED",
    "STRICT",
    "STRIP",
    "SUBSCRIPTION",
    "SUPPORT",
    "SYSID",
    "SYSTEM",
    "TABLES",
    "TABLESPACE",
    "TEMP",
    "TEMPLATE",
    "TEMPORARY",
    "TEXT",
    "TIES",
    "TRANSACTION",
    "TRANSFORM",
    "TRIGGER",
    "TRUNCATE",
    "TRUSTED",
    "TYPE",
    "TYPES",
    "UESCAPE",
    "UNBOUNDED",
    "UNCOMMITTED",
    "UNENCRYPTED",
    "UNKNOWN",
    "UNLISTEN",
    "UNLOGGED",
    "UNTIL",
    "UPDATE",
    "VACUUM",
    "VALID",
    "VALIDATE",
    "VALIDATOR",
    "VALUE",
    "VARYING",
    "VERSION",
    "VIEW",
    "VIEWS",
    "VOLATILE",
    "WHITESPACE",
    "WITHIN",
    "WITHOUT",
    "WORK",
    "WRAPPER",
    "WRITE",
    "XML",
    "YEAR",
    "YES",
    "ZONE",
  ]

  static let defaultColumnNameKeywords: Set<String> = [
    "BETWEEN",
    "BIGINT",
    "BIT",
    "BOOLEAN",
    "CHAR",
    "CHARACTER",
    "COALESCE",
    "DEC",
    "DECIMAL",
    "EXISTS",
    "EXTRACT",
    "FLOAT",
    "GREATEST",
    "GROUPING",
    "INOUT",
    "INT",
    "INTEGER",
    "INTERVAL",
    "JSON_ARRAY",
    "JSON_ARRAYAGG",
    "JSON_OBJECT",
    "JSON_OBJECTAGG",
    "LEAST",
    "NATIONAL",
    "NCHAR",
    "NONE",
    "NORMALIZE",
    "NULLIF",
    "NUMERIC",
    "OUT",
    "OVERLAY",
    "POSITION",
    "PRECISION",
    "REAL",
    "ROW",
    "SETOF",
    "SMALLINT",
    "SUBSTRING",
    "TIME",
    "TIMESTAMP",
    "TREAT",
    "TRIM",
    "VALUES",
    "VARCHAR",
    "XMLATTRIBUTES",
    "XMLCONCAT",
    "XMLELEMENT",
    "XMLEXISTS",
    "XMLFOREST",
    "XMLNAMESPACES",
    "XMLPARSE",
    "XMLPI",
    "XMLROOT",
    "XMLSERIALIZE",
    "XMLTABLE",
  ]

  static let defaultTypeFunctionNameKeywords: Set<String> = [
    "AUTHORIZATION",
    "BINARY",
    "COLLATION",
    "CONCURRENTLY",
    "CROSS",
    "CURRENT_SCHEMA",
    "FREEZE",
    "FULL",
    "ILIKE",
    "INNER",
    "IS",
    "ISNULL",
    "JOIN",
    "LEFT",
    "LIKE",
    "NATURAL",
    "NOTNULL",
    "OUTER",
    "OVERLAPS",
    "RIGHT",
    "SIMILAR",
    "TABLESAMPLE",
    "VERBOSE",
  ]

  static let defaultReservedKeywords: Set<String> = [
    "ALL",
    "ANALYSE",
    "ANALYZE",
    "AND",
    "ANY",
    "ARRAY",
    "AS",
    "ASC",
    "ASYMMETRIC",
    "BOTH",
    "CASE",
    "CAST",
    "CHECK",
    "COLLATE",
    "COLUMN",
    "CONSTRAINT",
    "CREATE",
    "CURRENT_CATALOG",
    "CURRENT_DATE",
    "CURRENT_ROLE",
    "CURRENT_TIME",
    "CURRENT_TIMESTAMP",
    "CURRENT_USER",
    "DEFAULT",
    "DEFERRABLE",
    "DESC",
    "DISTINCT",
    "DO",
    "ELSE",
    "END",
    "EXCEPT",
    "FALSE",
    "FETCH",
    "FOR",
    "FOREIGN",
    "FROM",
    "GRANT",
    "GROUP",
    "HAVING",
    "IN",
    "INITIALLY",
    "INTERSECT",
    "INTO",
    "LATERAL",
    "LEADING",
    "LIMIT",
    "LOCALTIME",
    "LOCALTIMESTAMP",
    "NOT",
    "NULL",
    "OFFSET",
    "ON",
    "ONLY",
    "OR",
    "ORDER",
    "PLACING",
    "PRIMARY",
    "REFERENCES",
    "RETURNING",
    "SELECT",
    "SESSION_USER",
    "SOME",
    "SYMMETRIC",
    "SYSTEM_USER",
    "TABLE",
    "THEN",
    "TO",
    "TRAILING",
    "TRUE",
    "UNION",
    "UNIQUE",
    "USER",
    "USING",
    "VARIADIC",
    "WHEN",
    "WHERE",
    "WINDOW",
    "WITH",
  ]

  static let defaultBareLabelKeywords: Set<String> = [
    "ABORT",
    "ABSENT",
    "ABSOLUTE",
    "ACCESS",
    "ACTION",
    "ADD",
    "ADMIN",
    "AFTER",
    "AGGREGATE",
    "ALL",
    "ALSO",
    "ALTER",
    "ALWAYS",
    "ANALYSE",
    "ANALYZE",
    "AND",
    "ANY",
    "ASC",
    "ASENSITIVE",
    "ASSERTION",
    "ASSIGNMENT",
    "ASYMMETRIC",
    "AT",
    "ATOMIC",
    "ATTACH",
    "ATTRIBUTE",
    "AUTHORIZATION",
    "BACKWARD",
    "BEFORE",
    "BEGIN",
    "BETWEEN",
    "BIGINT",
    "BINARY",
    "BIT",
    "BOOLEAN",
    "BOTH",
    "BREADTH",
    "BY",
    "CACHE",
    "CALL",
    "CALLED",
    "CASCADE",
    "CASCADED",
    "CASE",
    "CAST",
    "CATALOG",
    "CHAIN",
    "CHARACTERISTICS",
    "CHECK",
    "CHECKPOINT",
    "CLASS",
    "CLOSE",
    "CLUSTER",
    "COALESCE",
    "COLLATE",
    "COLLATION",
    "COLUMN",
    "COLUMNS",
    "COMMENT",
    "COMMENTS",
    "COMMIT",
    "COMMITTED",
    "COMPRESSION",
    "CONCURRENTLY",
    "CONFIGURATION",
    "CONFLICT",
    "CONNECTION",
    "CONSTRAINT",
    "CONSTRAINTS",
    "CONTENT",
    "CONTINUE",
    "CONVERSION",
    "COPY",
    "COST",
    "CROSS",
    "CSV",
    "CUBE",
    "CURRENT",
    "CURRENT_CATALOG",
    "CURRENT_DATE",
    "CURRENT_ROLE",
    "CURRENT_SCHEMA",
    "CURRENT_TIME",
    "CURRENT_TIMESTAMP",
    "CURRENT_USER",
    "CURSOR",
    "CYCLE",
    "DATA",
    "DATABASE",
    "DEALLOCATE",
    "DEC",
    "DECIMAL",
    "DECLARE",
    "DEFAULT",
    "DEFAULTS",
    "DEFERRABLE",
    "DEFERRED",
    "DEFINER",
    "DELETE",
    "DELIMITER",
    "DELIMITERS",
    "DEPENDS",
    "DEPTH",
    "DESC",
    "DETACH",
    "DICTIONARY",
    "DISABLE",
    "DISCARD",
    "DISTINCT",
    "DO",
    "DOCUMENT",
    "DOMAIN",
    "DOUBLE",
    "DROP",
    "EACH",
    "ELSE",
    "ENABLE",
    "ENCODING",
    "ENCRYPTED",
    "END",
    "ENUM",
    "ESCAPE",
    "EVENT",
    "EXCLUDE",
    "EXCLUDING",
    "EXCLUSIVE",
    "EXECUTE",
    "EXISTS",
    "EXPLAIN",
    "EXPRESSION",
    "EXTENSION",
    "EXTERNAL",
    "EXTRACT",
    "FALSE",
    "FAMILY",
    "FINALIZE",
    "FIRST",
    "FLOAT",
    "FOLLOWING",
    "FORCE",
    "FOREIGN",
    "FORMAT",
    "FORWARD",
    "FREEZE",
    "FULL",
    "FUNCTION",
    "FUNCTIONS",
    "GENERATED",
    "GLOBAL",
    "GRANTED",
    "GREATEST",
    "GROUPING",
    "GROUPS",
    "HANDLER",
    "HEADER",
    "HOLD",
    "IDENTITY",
    "IF",
    "ILIKE",
    "IMMEDIATE",
    "IMMUTABLE",
    "IMPLICIT",
    "IMPORT",
    "IN",
    "INCLUDE",
    "INCLUDING",
    "INCREMENT",
    "INDENT",
    "INDEX",
    "INDEXES",
    "INHERIT",
    "INHERITS",
    "INITIALLY",
    "INLINE",
    "INNER",
    "INOUT",
    "INPUT",
    "INSENSITIVE",
    "INSERT",
    "INSTEAD",
    "INT",
    "INTEGER",
    "INTERVAL",
    "INVOKER",
    "IS",
    "ISOLATION",
    "JOIN",
    "JSON",
    "JSON_ARRAY",
    "JSON_ARRAYAGG",
    "JSON_OBJECT",
    "JSON_OBJECTAGG",
    "KEY",
    "KEYS",
    "LABEL",
    "LANGUAGE",
    "LARGE",
    "LAST",
    "LATERAL",
    "LEADING",
    "LEAKPROOF",
    "LEAST",
    "LEFT",
    "LEVEL",
    "LIKE",
    "LISTEN",
    "LOAD",
    "LOCAL",
    "LOCALTIME",
    "LOCALTIMESTAMP",
    "LOCATION",
    "LOCK",
    "LOCKED",
    "LOGGED",
    "MAPPING",
    "MATCH",
    "MATCHED",
    "MATERIALIZED",
    "MAXVALUE",
    "MERGE",
    "METHOD",
    "MINVALUE",
    "MODE",
    "MOVE",
    "NAME",
    "NAMES",
    "NATIONAL",
    "NATURAL",
    "NCHAR",
    "NEW",
    "NEXT",
    "NFC",
    "NFD",
    "NFKC",
    "NFKD",
    "NO",
    "NONE",
    "NORMALIZE",
    "NORMALIZED",
    "NOT",
    "NOTHING",
    "NOTIFY",
    "NOWAIT",
    "NULL",
    "NULLIF",
    "NULLS",
    "NUMERIC",
    "OBJECT",
    "OF",
    "OFF",
    "OIDS",
    "OLD",
    "ONLY",
    "OPERATOR",
    "OPTION",
    "OPTIONS",
    "OR",
    "ORDINALITY",
    "OTHERS",
    "OUT",
    "OUTER",
    "OVERLAY",
    "OVERRIDING",
    "OWNED",
    "OWNER",
    "PARALLEL",
    "PARAMETER",
    "PARSER",
    "PARTIAL",
    "PARTITION",
    "PASSING",
    "PASSWORD",
    "PLACING",
    "PLANS",
    "POLICY",
    "POSITION",
    "PRECEDING",
    "PREPARE",
    "PREPARED",
    "PRESERVE",
    "PRIMARY",
    "PRIOR",
    "PRIVILEGES",
    "PROCEDURAL",
    "PROCEDURE",
    "PROCEDURES",
    "PROGRAM",
    "PUBLICATION",
    "QUOTE",
    "RANGE",
    "READ",
    "REAL",
    "REASSIGN",
    "RECHECK",
    "RECURSIVE",
    "REF",
    "REFERENCES",
    "REFERENCING",
    "REFRESH",
    "REINDEX",
    "RELATIVE",
    "RELEASE",
    "RENAME",
    "REPEATABLE",
    "REPLACE",
    "REPLICA",
    "RESET",
    "RESTART",
    "RESTRICT",
    "RETURN",
    "RETURNS",
    "REVOKE",
    "RIGHT",
    "ROLE",
    "ROLLBACK",
    "ROLLUP",
    "ROUTINE",
    "ROUTINES",
    "ROW",
    "ROWS",
    "RULE",
    "SAVEPOINT",
    "SCALAR",
    "SCHEMA",
    "SCHEMAS",
    "SCROLL",
    "SEARCH",
    "SECURITY",
    "SELECT",
    "SEQUENCE",
    "SEQUENCES",
    "SERIALIZABLE",
    "SERVER",
    "SESSION",
    "SESSION_USER",
    "SET",
    "SETOF",
    "SETS",
    "SHARE",
    "SHOW",
    "SIMILAR",
    "SIMPLE",
    "SKIP",
    "SMALLINT",
    "SNAPSHOT",
    "SOME",
    "SQL",
    "STABLE",
    "STANDALONE",
    "START",
    "STATEMENT",
    "STATISTICS",
    "STDIN",
    "STDOUT",
    "STORAGE",
    "STORED",
    "STRICT",
    "STRIP",
    "SUBSCRIPTION",
    "SUBSTRING",
    "SUPPORT",
    "SYMMETRIC",
    "SYSID",
    "SYSTEM",
    "SYSTEM_USER",
    "TABLE",
    "TABLES",
    "TABLESAMPLE",
    "TABLESPACE",
    "TEMP",
    "TEMPLATE",
    "TEMPORARY",
    "TEXT",
    "THEN",
    "TIES",
    "TIME",
    "TIMESTAMP",
    "TRAILING",
    "TRANSACTION",
    "TRANSFORM",
    "TREAT",
    "TRIGGER",
    "TRIM",
    "TRUE",
    "TRUNCATE",
    "TRUSTED",
    "TYPE",
    "TYPES",
    "UESCAPE",
    "UNBOUNDED",
    "UNCOMMITTED",
    "UNENCRYPTED",
    "UNIQUE",
    "UNKNOWN",
    "UNLISTEN",
    "UNLOGGED",
    "UNTIL",
    "UPDATE",
    "USER",
    "USING",
    "VACUUM",
    "VALID",
    "VALIDATE",
    "VALIDATOR",
    "VALUE",
    "VALUES",
    "VARCHAR",
    "VARIADIC",
    "VERBOSE",
    "VERSION",
    "VIEW",
    "VIEWS",
    "VOLATILE",
    "WHEN",
    "WHITESPACE",
    "WORK",
    "WRAPPER",
    "WRITE",
    "XML",
    "XMLATTRIBUTES",
    "XMLCONCAT",
    "XMLELEMENT",
    "XMLEXISTS",
    "XMLFOREST",
    "XMLNAMESPACES",
    "XMLPARSE",
    "XMLPI",
    "XMLROOT",
    "XMLSERIALIZE",
    "XMLTABLE",
    "YES",
    "ZONE",
  ]

  let unreservedKeywords: Set<String>
  let columnNameKeywords: Set<String>
  let typeFunctionNameKeywords: Set<String>
  let reservedKeywords: Set<String>
  let bareLabelKeywords: Set<String>

  init(
    unreservedKeywords: Set<String> = defaultUnreservedKeywords,
    columnNameKeywords: Set<String> = defaultColumnNameKeywords,
    typeFunctionNameKeywords: Set<String> = defaultTypeFunctionNameKeywords,
    reservedKeywords: Set<String> = defaultReservedKeywords,
    bareLabelKeywords: Set<String> = defaultBareLabelKeywords
  ) {
    self.unreservedKeywords = unreservedKeywords
    self.columnNameKeywords = columnNameKeywords
    self.typeFunctionNameKeywords = typeFunctionNameKeywords
    self.reservedKeywords = reservedKeywords
    self.bareLabelKeywords = bareLabelKeywords
  }

  static let `default`: KeywordManager = .init()

  struct _LazyComputedProperties {
    let allKeywords: Set<String>
    let sortedAllKeywords: Array<String>
    init(_ manager: KeywordManager) {
      self.allKeywords = (
        manager.unreservedKeywords
          .union(manager.columnNameKeywords)
          .union(manager.typeFunctionNameKeywords)
          .union(manager.reservedKeywords)
          .union(manager.bareLabelKeywords)
      )
      self.sortedAllKeywords = allKeywords.sorted()
    }
  }
  private var __lazyComputedProperties: _LazyComputedProperties? = nil
  private let _lazyComputedPropertiesQueue: DispatchQueue = .init(
    label: "jp.YOCKOW.PQMacros.KeywordManager.LazyComputedProperties",
    attributes: .concurrent
  )
  private var _lazyComputedProperties: _LazyComputedProperties {
    return _lazyComputedPropertiesQueue.sync {
      if let lazyComputedProperties = __lazyComputedProperties {
        return lazyComputedProperties
      }
      let lazyComputedProperties = _LazyComputedProperties(self)
      __lazyComputedProperties = lazyComputedProperties
      return lazyComputedProperties
    }
  }

  var allKeywords: Set<String> {
    return _lazyComputedProperties.allKeywords
  }

  var sortedAllKeywords: Array<String> {
    return _lazyComputedProperties.sortedAllKeywords
  }
}

public struct StaticKeywordExpander: MemberMacro {
  public enum Error: Swift.Error {
    case unsupportedType
  }

  private static func _expandStaticPropertiesOfTokenType(
    manager: KeywordManager
  ) throws -> [DeclSyntax] {
    var result: [DeclSyntax] = []
    var initialMap: [Character: [(String, IdentifierPatternSyntax)]] = [:]
    for keyword in manager.sortedAllKeywords {
      let unreserved = manager.unreservedKeywords.contains(keyword)
      let columnName = manager.columnNameKeywords.contains(keyword)
      let typeFunc = manager.typeFunctionNameKeywords.contains(keyword)
      let reserved = manager.reservedKeywords.contains(keyword)
      let bareLabel = manager.bareLabelKeywords.contains(keyword)
      let swiftIdentifier = keyword._swiftIdentifier
      let initial = keyword.first!
      initialMap[initial] = (initialMap[initial] ?? []) + [(keyword, swiftIdentifier)]

      result.append("""
      /// A token of keyword "\(raw: keyword)".
      public static let \(swiftIdentifier): Token = Keyword(
        rawValue: \(StringLiteralExprSyntax(content: keyword)),
        isUnreserved: \(BooleanLiteralExprSyntax(unreserved)),
        isAvailableForColumnName: \(BooleanLiteralExprSyntax(columnName)),
        isAvailableForTypeOrFunctionName: \(BooleanLiteralExprSyntax(typeFunc)),
        isReserved: \(BooleanLiteralExprSyntax(reserved)),
        isBareLabel: \(BooleanLiteralExprSyntax(bareLabel))
      )
      """)
    }

    ADD_KEYWORD_JUDGEMENT:
    do {
      /*

       Add a type like below:

       ```
       private struct __Keyword {
       static let closures: [Character: @Sendable (String) -> Keyword?] = [
           "A": { // Inital A
           switch $0.dropFirst() {
           case "BORT": return .abort
           case "BSENT": return .absent
           :
           default: return nil
           }
           },
           :
           :
           "Z": { // Initial Z
           ...
           },
         ]
       }
       ```

       */

      func __closure(of initial: Character) -> ClosureExprSyntax {
        let returnNilStmt = ReturnStmtSyntax(
          returnKeyword: .keyword(.return, trailingTrivia: .space),
          expression: NilLiteralExprSyntax(nilKeyword: .keyword(.nil))
        )
        let returnNilCodeBlockItem = CodeBlockItemSyntax(item: .init(returnNilStmt))

        guard let keywordAndIdentifierList = initialMap[initial] else {
          return ClosureExprSyntax(statements: [returnNilCodeBlockItem])
        }

        let switchSubject: FunctionCallExprSyntax = ({
          let dollar0DeclRefExpr = DeclReferenceExprSyntax(baseName: .dollarIdentifier("$0"))
          let dropFirstDeclRefExpr = DeclReferenceExprSyntax(baseName: .identifier("dropFirst"))
          let dropFirstMemberExpr = MemberAccessExprSyntax(
            base: dollar0DeclRefExpr,
            period: .periodToken(),
            declName: dropFirstDeclRefExpr
          )
          return FunctionCallExprSyntax(
            calledExpression: dropFirstMemberExpr,
            leftParen: .leftParenToken(),
            arguments: [],
            rightParen: .rightParenToken()
          )
        })()

        let switchCaseList: SwitchCaseListSyntax = ({
          func __case(for keyword: String, identifier: IdentifierPatternSyntax) -> SwitchCaseSyntax {
            let label: SwitchCaseLabelSyntax = ({
              let expr = ExpressionPatternSyntax(expression: StringLiteralExprSyntax(content: String(keyword.dropFirst())))
              let item = SwitchCaseItemSyntax(pattern: expr)
              return SwitchCaseLabelSyntax(
                caseKeyword: .keyword(.case, trailingTrivia: .space),
                caseItems: [item],
                trailingTrivia: .space
              )
            })()
            let statements: CodeBlockItemListSyntax = ({
              var memberExpr = MemberAccessExprSyntax(period: .periodToken(), name: identifier.identifier)
              if identifier.identifier.text == "none" || identifier.identifier.text == "`none`" {
                // It doesn't mean `nil`!
                memberExpr.base = .init(DeclReferenceExprSyntax(baseName: .identifier("Token")))
              }
              let returnMemberStmt = ReturnStmtSyntax(
                returnKeyword: .keyword(.return, trailingTrivia: .space),
                expression: memberExpr
              )
              let item = CodeBlockItemSyntax(item: .init(returnMemberStmt))
              return [item]
            })()
            return SwitchCaseSyntax(
              label: .init(label),
              statements: statements,
              trailingTrivia: .newline
            )
          }

          let defaultReturnNilCase = SwitchCaseSyntax(
            label: .default(.init(trailingTrivia: .space)),
            statements: [returnNilCodeBlockItem],
            trailingTrivia: .newline
          )

          var switchCaseList: SwitchCaseListSyntax = keywordAndIdentifierList.reduce(into: []) {
            $0.append(.init(__case(for: $1.0, identifier: $1.1)))
          }
          switchCaseList.append(.init(defaultReturnNilCase))
          return switchCaseList
        })()

        let switchExpr = SwitchExprSyntax(
          switchKeyword: .keyword(.switch, trailingTrivia: .space),
          subject: switchSubject,
          leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
          cases: switchCaseList
        )
        return ClosureExprSyntax(statements: [.init(item: .init(switchExpr))])
      }

      func __dictionaryElement(of initial: Character) -> DictionaryElementSyntax {
        let keyLiteral = StringLiteralExprSyntax(content: String(initial))
        return DictionaryElementSyntax(
          key: keyLiteral,
          value: __closure(of: initial),
          trailingComma: .commaToken(trailingTrivia: .newline)
        )
      }

      let dictionaryElementList: DictionaryElementListSyntax = initialMap.keys.sorted().reduce(into: []) {
        $0.append(__dictionaryElement(of: $1))
      }

      let dictionaryExpr = DictionaryExprSyntax(
        leftSquare: .leftSquareToken(trailingTrivia: .newline),
        content: .elements(dictionaryElementList),
        rightSquare: .rightSquareToken(trailingTrivia: .newline)
      )

      result.append("""
      private struct __Keyword {
        static let closures: [Character: @Sendable (String) -> Token?] = \(dictionaryExpr)
      }
      """)
    }

    result.append("""
    /// Returns an instance of `Keyword` represented by `string` if exists.
    public static func keyword(from string: String) -> Keyword? {
      guard let initial = string.first else { return nil }
      let ucInitial = initial.uppercased()
      do { // Only one character?
        var iter = ucInitial.makeIterator()
        guard iter.next() != nil else { return nil }
        guard iter.next() == nil else { return nil }
      }
      guard let judge = __Keyword.closures[ucInitial.first.unsafelyUnwrapped] else { return nil }
      return judge(string.uppercased()) as? Keyword
    }
    """)

    return result
  }

  private static func _expandStaticPropertiesOfSingleTokenType(
    manager: KeywordManager
  ) throws -> [DeclSyntax] {
    var result: [DeclSyntax] = []
    
    for keyword in manager.sortedAllKeywords {
      let identifier = keyword._swiftIdentifier
      result.append("""
      /// A single token of keyword "`\(raw: keyword)`"
      public static let \(identifier): SingleToken = SingleToken(Token.\(identifier))
      """)
    }

    return result
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if let sqlTokenClassDecl = declaration.as(ClassDeclSyntax.self),
       sqlTokenClassDecl.name.text == "Token" {
      return try _expandStaticPropertiesOfTokenType(manager: .default)
    } else if let singleTokenStructDecl = declaration.as(StructDeclSyntax.self),
              singleTokenStructDecl.name.text == "SingleToken" {
      return try _expandStaticPropertiesOfSingleTokenType(manager: .default)
    } else {
      throw Error.unsupportedType
    }
  }
}
