require "strong_arms/version"
require "strong_arms/utilities"
require "strong_arms/exception_methods"
require "strong_arms/assertions"
require "active_support/all"

module StrongArms
  include Utilities
  include ExceptionMethods
  include Assertions
  include ActiveSupport

  STRICT_ENV = 'development'.freeze

  class UnhandledKeys < StandardError; end
  class ConfigurationMissing < StandardError; end
  class ValuesMissing < ArgumentError; end
  class MultipleAttributesError < ArgumentError; end
  class RequiredValueMissing < ArgumentError; end

  class << self
    attr_accessor :configuration

    def env
      configuration.env
    end
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :env

    def initialize
      @env = STRICT_ENV
    end
  end

  def ignore(*args)
    @keys_to_ignore = args
  end

  def permit(attribute, **options)
    attributes = [attribute].flatten
    multiple_attributes_error(attributes)

    set_handler(attribute, options, type: :input)
  end

  def one_nested(association, options = {})
    nested(association: association, has_many: false, options: options)
  end

  def many_nested(association, options = {})
    nested(association: association, has_many: true, options: options)
  end

  def nested(association:, has_many:, options: {})
    format = options.fetch(:format, true)
    model = options[:model]
    merged_handler_options = { has_many: has_many }.merge(model: model)
    handler_options = model ? merged_handler_options : { has_many: has_many }
    modified_key = format ? nested_attributes_key(association) : association

    set_handler(modified_key, handler_options, type: :association)
  end

  def flex(args)
    environment_configured_error

    useful_args = action_controller_args?(args) ? accessible_hash(args) : args
    exposed_args = expose_data_key_if_present(useful_args)

    empty_arguments_error(exposed_args)
    unhandled_keys_error(exposed_args)

    reduce_handlers(handlers_values, exposed_args)
  end

  def handlers
    @handlers ||= {}
  end

  def keys_to_ignore
    @keys_to_ignore ||= []
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

    missing_value_for_required_input_error(name, value_at_name, options)

    return {} if value_is_absent?(value_at_name, allow_nil: allow_nil)

    send("parse_#{type}", name: name, value: value_at_name, options: options)
  end

  def parse_input(name:, value:, options:)
    { name => value }
  end

  def parse_association(name:, value:, options:)
    strong_arm = find_strong_arm(name, options)
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
