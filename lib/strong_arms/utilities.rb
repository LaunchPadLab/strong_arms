module Utilities
  def build_handler(name, options, type:)
    {
      name: name,
      options: options,
      type: type,
    }
  end

  def expose_data_key_if_present(args)
    if args[:data].present?
      args[:data]
    else
      args
    end
  end

  def value_is_absent?(value, allow_nil: false)
    return false if allow_nil
    return true if value.nil?

    if value.is_a? Hash
      value.blank?
    else
      [value].flatten.blank?
    end
  end

  def find_strong_arm(attributes_key, options)
    model_alias = options[:model]
    model_name =
      model_name_from_attributes_key(attributes_key, model_alias: model_alias)
    strong_arm = "#{model_name}StrongArm"
    strong_arm.constantize
  end

  def handlers_values
    handlers.values
  end

  private

  def model_name_from_attributes_key(name, model_alias: nil)
    if model_alias
      model_alias.to_s.camelize
    else
      name.to_s.
        gsub('s_attributes', '').
        gsub('_attributes', '').
        camelize
    end
  end

  def unhandled_keys(args)
    keys = symbolized_keys_array(args)
    keys - handlers_keys - keys_to_ignore
  end

  def handlers_keys
    handlers.keys.flatten.uniq
  end


  def symbolized_keys_array(args)
    args.keys.map(&:to_sym)
  end

  def accessible_hash(args)
    args.to_unsafe_h.with_indifferent_access
  end

  def action_controller_args?(args)
    args.class.name == 'ActionController::Parameters'
  end

  def length_is_greater_than?(array, value)
    array.length > value
  end

  def length_is_equal_to?(array, value)
    array.length == value
  end

  def to_class_name(object)
    to_name(object.class)
  end

  def to_name(klass)
    klass.name
  end
end
