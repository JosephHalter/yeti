module Yeti
  class Editor
    include ActiveModel::Validations
    include ActiveModel::Dirty
    class InvalidDate < ::StandardError; end

    attr_reader :context
    delegate :id, :to_param, to: :edited, allow_nil: true

    def self.from_id(context, id)
      new context, (find_by_id context, id if id)
    end

    def initialize(context, edited=nil)
      @context = context
      @edited = edited
    end

    def edited
      @edited ||= self.class.new_object context
    end

    def persisted?
      edited ? edited.persisted? : false
    end

    def errors
      @errors ||= ::Yeti::Errors.new(
        self,
        untranslated: self.class.untranslated?
      )
    end

    def update_attributes(attrs)
      self.attributes = attrs
      save
    end

    def attributes
      attributes = {}
      self.class.attributes.each do |key|
        attributes[key] = send key
      end
      attributes
    end

    def attributes=(attrs)
      self.class.attributes.each do |key|
        self.send "#{key}=", attrs[key] if attrs.has_key? key
      end
    end

    def save(opts={})
      if opts.fetch :validate, true
        return false unless valid?
      end
      persist!
      @previously_changed = changes
      changed_attributes.clear
      true
    end

    def persist!
      raise NotImplementedError, "#{self.class}#persist!"
    end

    def without_error?
      errors.empty?
    end

    def mandatory?(column)
      self.class.validators_on(column).any? do |validator|
        validator.kind_of? ::ActiveModel::Validations::PresenceValidator
      end
    end

    def ==(other)
      other.equal?(self) || (
        persisted? &&
        other.instance_of?(self.class) &&
        other.persisted? &&
        other.id==id
      )
    end
    alias_method :eql?, :==

    def hash
      id.hash
    end

    def attributes_for_persist
      attributes = {}
      self.class.attributes.each do |key|
        value = send key
        opts = self.class.attribute_options[key]
        attributes[key] = format_input_for_persist value, opts
      end
      attributes
    end

  protected

    # ~~~ methods to be implemented in subclasses ~~~
    def self.find_by_id(context, id)
      raise NotImplementedError, "#{inspect}.find_by_id"
    end

    def self.new_object(context)
      raise NotImplementedError, "#{inspect}.new_object"
    end

  private

    def self.attribute(name, opts={})
      opts[:attribute_name] = name
      opts[:from] = :edited unless opts.has_key? :from
      attribute_options[name.to_sym] = opts
      define_attribute_methods attributes
      from = case opts[:from].to_s
      when ""
        "nil"
      when /^\.(.*)/
        $1
      when /\./
        opts[:from]
      else
        "#{opts[:from]}.#{name}"
      end
      class_eval """
        def #{name}
          unless defined? @#{name}
            opts = self.class.attribute_options[:#{name}]
            @#{name} = format_output #{from}, opts
          end
          @#{name}
        end
        def #{name}=(value)
          opts = self.class.attribute_options[:#{name}]
          value = format_input value, opts
          return if value==#{name}
          #{name}_will_change!
          @#{name} = value
          original_value = changed_attributes[\"#{name}\"]
          changed_attributes.delete \"#{name}\" if value==original_value
        end
      """
    end

    def self.attributes
      attribute_options.keys
    end

    def self.attribute_options
      @attribute_options ||= {}
    end

    def self.dont_translate_error_messages
      @untranslated = true
    end

    def self.untranslated?
      !!@untranslated
    end

    def format_input(value, attribute_opts)
      value = value.clean.strip if value.respond_to? :clean
      value
    end

    def format_input_for_persist(value, attribute_opts)
      case attribute_opts[:as]
      when :date
        case value
        when Date
          value
        else
          format_date value
        end
      else
        value
      end
    end

    def format_date(value)
      return unless value
      Date.parse value
    rescue ArgumentError
      raise InvalidDate, value
    end

    def format_output(value, attribute_opts)
      value
    end

  end
end
