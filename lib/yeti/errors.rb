module Yeti
  class Errors < ::ActiveModel::Errors

      def initialize(base, opts={})
        super base
        @untranslated = opts.fetch :untranslated, false
      end

      def untranslated?
        @untranslated
      end

    private

      def normalize_message(attribute, message, options)
        message ||= :invalid
        if untranslated? && !message.is_a?(Proc)
          message
        else
          super
        end
      end

  end
end
