module Assertions
  def required_input_value_missing?(options, value)
    required_input?(options) && value.blank?
  end

  def required_input?(options)
    options[:required]
  end

  # NOTE: TBD
  # def all_values_empty?(values)
  #   values.all? do |value|
  #     value.nil? || value == ""
  #   end
  # end

  def multiple_attributes?(attribute)
    length_is_greater_than?(attribute, 1)
  end

  def unhandled_keys_present?(args)
    unhandled_keys(args).present?
  end

  # ActiveSupport definition
  # def blank?
  #   respond_to?(:empty?) ? !!empty? : !self
  # end
end
