/* *************************************************************************************************
 GenericOption.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

/// An element of generic options. This is described as `generic_option_elem` in "gram.y".
public struct GenericOption: TokenSequenceGenerator {
  /// Representation of `generic_option_name` in "gram.y".
  public struct Name: Sendable {
    public let name: ColumnLabel

    public var token: Token {
      return name.token
    }

    public init(_ name: ColumnLabel) {
      self.name = name
    }
  }

  /// Representation of `generic_option_arg` in "gram.y.
  public struct Argument: Sendable {
    public let argument: StringConstantExpression

    public init(_ argument: StringConstantExpression) {
      self.argument = argument
    }
  }

  public let name: Name

  public let argument: Argument

  @inlinable
  public var tokens: Array<Token> {
    return [name.name.token, argument.argument.token]
  }

  public init(name: Name, argument: Argument) {
    self.name = name
    self.argument = argument
  }

  public init(name: ColumnLabel, argument: StringConstantExpression) {
    self.name = Name(name)
    self.argument = Argument(argument)
  }
}

/// A list of `GenericOption`. This is described as `generic_option_list` in "gram.y".
public struct GenericOptionList: TokenSequenceGenerator,
                                 InitializableWithNonEmptyList,
                                 ExpressibleByArrayLiteral {
  public var options: NonEmptyList<GenericOption>

  public var tokens: JoinedTokenSequence {
    return options.joinedByCommas()
  }

  public init(_ options: NonEmptyList<GenericOption>) {
    self.options = options
  }
}

/// A clause to provide generic options. This is described as `create_generic_options` in "gram.y".
public struct GenericOptionsClause: Clause {
  public var options: GenericOptionList

  public var tokens: JoinedTokenSequence {
    return SingleToken.options.followedBy(parenthesized: options)
  }

  public init(_ options: GenericOptionList) {
    self.options = options
  }
}
