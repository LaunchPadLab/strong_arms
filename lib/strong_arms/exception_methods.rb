module ExceptionMethods
  def unhandled_keys_error(args)
    if unhandled_keys(args).present?
      keys = unhandled_keys(args)
      message = "#{name} received unhandled keys: #{keys.join(', ')}."

      raise_or_log_error do
        StrongArms::UnhandledKeys.new(message)
      end
    end
  end

  def empty_arguments_error(args)
    if args.blank?
      raise_or_log_error do
        StrongArms::ValuesMissing.new('No values were passed.')
      end
    end
  end

  def multiple_attributes_error(attributes)
    if multiple_attributes?(attributes)
      message = "#{name} recieved multiple attributes for a single input."

      raise_or_log_error do
        StrongArms::MultipleAttributesError.new(message)
      end
    end
  end

  def missing_value_for_required_input_error(name, value, options)
    if required_input_value_missing?(options, value)
      raise_or_log_error do
        StrongArms::RequiredValueMissing.
          new("No value for required input: #{name}.")
      end
    end
  end

  def environment_configured_error
    if StrongArms.configuration.nil?
      message = "StrongArms must be configured to your environment, see README for getting started."
      raise StrongArms::ConfigurationMissing.new(message)
    end
  end
end
