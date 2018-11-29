module ExceptionMethods
  def missing_parser_exception
    raise ArgumentError,
      "#{name}: No parser specified for input with multiple values."
  end

  def unhandled_keys_exception(args)
    keys = unhandled_keys(args)
    Errors::UnhandledKeys.
      new("#{name} received unhandled keys: #{keys.join(', ')}.")
  end

  def empty_arguments_exception
    ArgumentError.new('No values were passed.')
  end

  def missing_parsers_for_multiple_attributes_exception
    ArgumentError.
      new("#{name} no parser specified for input with multiple values.")
  end

  def multiple_attributes_exception
    ArgumentError.
      new("#{name} recieved multiple attributes for a single input.")
  end

  def missing_value_for_required_input_exception(name)
    ArgumentError.new("No value for required input: #{name}.")
  end
end
