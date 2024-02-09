/* *************************************************************************************************
 SQLTokenSequence+Functions.swift
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

// TODO: Add more and more functions?

extension FunctionCall {
  public func numerOfNonnulls<each T: SQLTokenSequence>(_ argument: repeat each T) -> FunctionCall {
    return FunctionCall(name: .init(name: "num_nonnulls"), argument: repeat each argument)
  }

  public func numerOfNonnulls(_ arguments: [any SQLTokenSequence]) -> FunctionCall {
    return FunctionCall(name: .init(name: "num_nonnulls"), arguments: arguments)
  }

  public func numerOfNulls<each T: SQLTokenSequence>(_ argument: repeat each T) -> FunctionCall {
    return FunctionCall(name: .init(name: "num_nulls"), argument: repeat each argument)
  }

  public func numerOfNulls(_ arguments: [any SQLTokenSequence]) -> FunctionCall {
    return FunctionCall(name: .init(name: "num_nulls"), arguments: arguments)
  }
}

// MARK: - Mathematical functions
extension FunctionCall {
  public static func absolute<T>(_ expression: T) -> FunctionCall where T: SQLTokenSequence{
    return FunctionCall(name: .init(name: .abs), argument: expression)
  }

  public static func absolute<T>(_ integer: T) -> FunctionCall where T: FixedWidthInteger {
    return absolute(SingleToken.integer(integer))
  }

  public static func absolute<T>(_ float: T) -> FunctionCall where T: BinaryFloatingPoint & CustomStringConvertible {
    return absolute(SingleToken.float(float))
  }

  public static func ceil<T>(_ expression: T) -> FunctionCall where T: SQLTokenSequence {
    return FunctionCall(name: .init(name: .ceil), argument: expression)
  }

  public static func ceil<T>(_ integer: T) -> FunctionCall where T: FixedWidthInteger {
    return ceil(SingleToken.integer(integer))
  }

  public static func ceil<T>(_ float: T) -> FunctionCall where T: BinaryFloatingPoint & CustomStringConvertible {
    return ceil(SingleToken.float(float))
  }

  public static func floor<T>(_ expression: T) -> FunctionCall where T: SQLTokenSequence {
    return FunctionCall(name: .init(name: .floor), argument: expression)
  }

  public static func floor<T>(_ integer: T) -> FunctionCall where T: FixedWidthInteger {
    return floor(SingleToken.integer(integer))
  }

  public static func floor<T>(_ float: T) -> FunctionCall where T: BinaryFloatingPoint & CustomStringConvertible {
    return floor(SingleToken.float(float))
  }

  public static func round<T>(_ expression: T) -> FunctionCall where T: SQLTokenSequence {
    return FunctionCall(name: .init(name: .round), argument: expression)
  }

  public static func round<T>(_ integer: T) -> FunctionCall where T: FixedWidthInteger {
    return floor(SingleToken.integer(integer))
  }

  public static func round<T>(_ float: T) -> FunctionCall where T: BinaryFloatingPoint & CustomStringConvertible {
    return floor(SingleToken.float(float))
  }
}


// MARK: - String functions
extension FunctionCall {
  public static func concatenate<each T: SQLTokenSequence>(_ expression: repeat each T) -> FunctionCall {
    return FunctionCall(name: .init(name: .concat), argument: repeat each expression)
  }

  public static func concatenate(_ expressions: [any SQLTokenSequence]) -> FunctionCall {
    return FunctionCall(name: .init(name: .concat), arguments: expressions)
  }

  public static func concatenate(separator: String, _ expressions: [any SQLTokenSequence]) -> FunctionCall {
    var arguments: [any SQLTokenSequence] = [SingleToken.string(separator)]
    arguments.append(contentsOf: expressions)
    return FunctionCall(name: .init(name: "concat_ws"), arguments: arguments)
  }

  public static func concatenate<each T: SQLTokenSequence>(separator: String, _ expression: repeat each T) -> FunctionCall {
    var expressions: [any SQLTokenSequence] = []
    repeat (expressions.append(each expression))
    return concatenate(separator: separator, expressions)
  }

  public static func format(_ formatter: String, _ expressions: [any SQLTokenSequence]) -> FunctionCall {
    var arguments: [any SQLTokenSequence] = [SingleToken.string(formatter)]
    arguments.append(contentsOf: expressions)
    return FunctionCall(name: .init(name: .format), arguments: arguments)
  }

  public static func format<each T: SQLTokenSequence>(_ formatter: String, _ expression: repeat each T) -> FunctionCall {
    var expressions: [any SQLTokenSequence] = []
    repeat (expressions.append(each expression))
    return format(formatter, expressions)
  }

  public static func substring<T>(_ text: T, startIndex: Int, count: Int? = nil) -> FunctionCall where T: SQLTokenSequence {
    var expressions: [any SQLTokenSequence] = [text, SingleToken.integer(startIndex)]
    if let count {
      expressions.append(SingleToken.integer(count))
    }
    return FunctionCall(name: .init(name: "substr"), arguments: expressions)
  }
}
