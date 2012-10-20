module Yeti
  class Context
    class NoAccount
      attr_reader :id
    end

    delegate :id, to: :account, prefix: :account

    def initialize(hash)
      @given_account_id = hash.fetch(:account_id)
    end

    def account
      @account ||= find_account_by_id given_account_id if given_account_id
      @account ||= no_account
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
