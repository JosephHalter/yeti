module Yeti
  class Editor
    include ActiveModel::Validations
    include ActiveModel::Dirty

    attr_reader :context
    delegate :id, to: :edited

    def initialize(context, given_id)
      @context = context
      @given_id = given_id
    end

    def errors
      @errors ||= ::Yeti::Errors.new(
        self,
        untranslated: self.class.untranslated?
      )
    end

    def edited
      @edited ||= if given_id
        find_by_id given_id.to_i
      else
        new_object
      end
    end

    def find_by_id(id)
      raise NotImplementedError
    end

    def new_object
      raise NotImplementedError
    end

    def persisted?
      !!given_id
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

    def save
      return false unless valid?
      persist!
      @previously_changed = changes
      changed_attributes.clear
      true
    end

    def persist!
      raise NotImplementedError
    end

  private

    attr_reader :given_id

    def self.attribute(name, opts={})
      self.attributes << name
      define_attribute_methods attributes
      from = opts[:from] || :edited
      class_eval """
        def #{name}
          @#{name} = #{from}.#{name} unless defined? @#{name}
          @#{name}
        end
        def #{name}=(value)
          value = (value.to_s.clean.strip if value)
          return if value==#{name}
          #{name}_will_change!
          @#{name} = value
          original_value = changed_attributes[\"#{name}\"]
          changed_attributes.delete \"#{name}\" if value==original_value
        end
      """
    end

    def self.attributes
      @attributes ||= []
    end

    def self.dont_translate_error_messages
      @untranslated = true
    end

    def self.untranslated?
      !!@untranslated
    end

  end
end
