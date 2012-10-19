module Yeti
  class Context
    class NoAccount
      attr_reader :id
    end

    def initialize(hash)
      @given_account_id = hash.fetch(:account_id)
    end

    def account
      @account ||= find_account_by_id(given_id) || no_account
    end

    def find_account_by_id(id)
      raise NotImplementedError
    end

  private

    attr_reader :given_account_id

    def no_account
      NoAccount.new
    end

  end
end
