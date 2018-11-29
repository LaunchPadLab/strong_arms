require "strong_arms/version"
require "strong_arms/utilities"
require "strong_arms/errors"
require "strong_arms/exception_methods"
require "strong_arms/assertions"
require "active_support/all"

module StrongArms
  include Utilities
  include Errors
  include ExceptionMethods
  include Assertions
  include ActiveSupport

  def handlers
    @handlers ||= {}
  end

  def ignore(*args)
    @keys_to_ignore = args
  end

  def keys_to_ignore
    @keys_to_ignore ||= []
  end

  def permit(attribute, **options)
    attributes = [attribute].flatten

    if multiple_attributes?(attributes)
      raise multiple_attributes_exception
    end

    set_handler(attribute, options, type: :input)
  end

  def one_nested(association, format: true)
    modified_key = format ? nested_attributes_key(association) : association
    set_handler(modified_key, { has_many: false }, type: :association)
  end

  def many_nested(association, format: true)
    modified_key = format ? nested_attributes_key(association) : association
    set_handler(modified_key, { has_many: true }, type: :association)
  end

  def flex(args)
    _args = action_controller_args?(args) ? accessible_hash(args) : args
    exposed_args = expose_data_key_if_present(_args)

    raise empty_arguments_exception if exposed_args.blank?
    if unhandled_keys_present?(exposed_args)
      raise unhandled_keys_exception(exposed_args)
    end

    reduce_handlers(handlers_values, exposed_args)
  end

  def nested_attributes_key(association)
    "#{association}_attributes".to_sym
  end

  def set_handler(name, options, type:)
    handlers[name] =
      build_handler(name, options, type: type)
  end

  def reduce_handlers(handlers, args)
    return {} if handlers.empty?

    handlers.reduce({}) do |new_hash, handler|
      parsed_handler = extract_handler_values_and_parse(handler, args)
      new_hash.merge(parsed_handler)
    end
  end

  def extract_handler_values_and_parse(handler, args)
    name = handler[:name]
    options = handler[:options]
    type = handler[:type]
    allow_nil = options[:allow_nil]
    value_at_name = args[name]

    if required_input_value_missing?(options, value_at_name)
      raise missing_value_for_required_input_exception(name)
    end

    return {} if value_is_absent?(value_at_name, allow_nil: allow_nil)

    send("parse_#{type}", name: name, value: value_at_name, options: options)
  end

  def parse_input(name:, value:, options:) # options goes unused
    { name => value }
  end

  def parse_association(name:, value:, options:)
    strong_arm = find_strong_arm(name)
    wrapped_values = [value].flatten
    has_many = options[:has_many]

    strained_values = wrapped_values.map do |wrapped_value|
      strong_arm.flex(wrapped_value)
    end

    if has_many
      { name => strained_values }
    else
      { name => strained_values.pop }
    end
  end
end
