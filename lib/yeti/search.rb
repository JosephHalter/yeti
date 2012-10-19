module Yeti
  class Search

    attr_reader :search, :page
    delegate :to_ary, :empty?, :each, :group_by, :size, to: :results

    def initialize(context, hash)
      @context = context
      @search = hash[:search] || {}.with_indifferent_access
      @page = hash[:page] || 1
      @per_page = hash[:per_page] || 20
    end

    def page_count
      paginated_results.page_count
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

  private

    attr_reader :context, :per_page

    # ~~~ private instance methods ~~~
    def delegate_to_search_pattern
      /(?:_equals|_contains|_gte|_lte)\z/
    end

    def paginated_results
      raise NotImplementedError
    end

  end
end
