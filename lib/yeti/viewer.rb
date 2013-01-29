module Yeti
  class Viewer

    attr_reader :context, :decorated
    delegate :id, :to_param, :persisted?, to: :decorated

    def initialize(context, decorated)
      @context = context
      @decorated = decorated
    end

    def self.from_id(context, id)
      new context, (find_by_id context, id if id)
    end

    def ==(other)
      other.equal?(self) || (other.instance_of?(self.class) && other.id==id)
    end
    alias_method :eql?, :==

  protected

    # ~~~ methods to be implemented in subclasses ~~~
    def self.find_by_id(context, id)
      raise NotImplementedError, "#{inspect}.find_by_id"
    end

  end
end
