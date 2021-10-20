require "active_support/core_ext/enumerable"

module Yeti
  class Editor
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include ActiveModel::Dirty

    def self.inherited(subclass)
      subclass.dont_translate_error_messages if untranslated?
      super
    end

    def self.from_id(context, id)
      new context, (find_by_id context, id if id)
    end

    attr_reader :context
    delegate :id, :to_param, to: :edited, allow_nil: true

    def initialize(context, edited=nil)
      super()
      @context = context
      @edited = edited
      load_from_edited
    end

    def edited
      @edited ||= self.class.new_object context
    end

    def persisted?
      edited && edited.persisted?
    end

    def update_attributes(attrs={})
      self.attributes = attrs
      save
    end

    def save(opts={})
      if opts.fetch :validate, true
        return false unless valid?
      end
      persist!
      changes_applied
      true
    end

    def persist!
      raise NotImplementedError, "#{self.class}#persist!"
    end

    def without_error?
      errors.empty?
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

    # Override ActiveModel::Attributes#attributes, with the behaviour of returning
    # what the user entered without any type cast
    def attributes
      @attributes.values_before_type_cast.with_indifferent_access
    end

    # Returns attributes as they should be persisted, which means after type cast
    def attributes_for_persist
      @attributes.keys.index_with do |key|
        @attributes[key].value_for_database
      end.with_indifferent_access
    end

    # Do the same as ActiveModel::AttributeAssignment#attributes=/assign_attributes
    def attributes=(attrs)
      attrs = attrs.with_indifferent_access
      self.class.attribute_names.each do |key|
        send "#{key}=", attrs[key] if attrs.has_key? key
      end
    end

    # Overrides ActiveModel::Validations
    def errors
      @errors ||= ::Yeti::Errors.new(
        self,
        untranslated: self.class.untranslated?
      )
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

    def self.dont_translate_error_messages
      @untranslated = true
    end

    def self.untranslated?
      !!@untranslated
    end

    # Overrides ActiveModel::Attributes
    def write_attribute(attr_name, value)
      value = value.clean.strip if value.respond_to? :clean
      super(attr_name, value)
    end

    def load_from_edited
      return unless @edited
      self.class.attribute_names.each do |key|
        next unless @edited.respond_to?(key)
        @attributes.write_from_database(key, @edited.public_send(key))
      end
    end
  end
end
