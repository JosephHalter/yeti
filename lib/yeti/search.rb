module Yeti
  class Search

    attr_reader :context
    delegate :to_ary, :empty?, :each, :group_by, :size, to: :results
    delegate :page_count, to: :paginated_results

    def initialize(context, hash)
      @context = context
      @hash = hash
    end

    def search
      @search ||= (hash[:search] || {}).with_indifferent_access
    end

    def page
      @page ||= [1, (hash[:page] || 1).to_i].max
    end

    def per_page
      @per_page ||= begin
        per_page = [1, (hash[:per_page] || 20).to_i].max
        max = self.class.max_per_page
        max ? [per_page, max].min : per_page
      end
    end

    def count
      paginated_results.pagination_record_count
    end

    def results
      paginated_results.all
    end

    def respond_to?(method)
      super || method.to_s=~delegate_to_search_pattern
    end

    def method_missing(method, *args, &block)
      case method.to_s
      when /_id_equals\z/
        search[method].to_i
      when delegate_to_search_pattern
        search[method]
      else
        super
      end
    end

    def paginated_results
      raise NotImplementedError
    end

  private

    attr_reader :hash

    # ~~~ private class methods ~~~
    def self.max_per_page(value=nil)
      value ? @max_per_page = value : @max_per_page
    end

    # ~~~ private instance methods ~~~
    def delegate_to_search_pattern
      /(?:_equals|_contains|_gte|_lte)\z/
    end

  end
end
