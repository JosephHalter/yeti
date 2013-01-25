module Yeti
  class Viewer

    attr_reader :context, :decorated
    delegate :id, :to_param, :persisted?, to: :decorated

    def initialize(context, decorated)
      @context = context
      @decorated = decorated
    end

    def self.from_id(context, id)
      new context, (find_by_id id if id)
    end

  protected

    def self.find_by_id(id)
      raise NotImplementedError, "#{inspect}.find_by_id"
    end

  end
end
