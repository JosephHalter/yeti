RSpec::Matchers.define :delegates do |delegated_method|
  match do |subject|
    stubbed = send(@delegate).stub(@delegate_method)
    stubbed.with @delegate_params if @delegate_params
    stubbed.and_return expected=mock
    subject.send(delegated_method) === expected
  end

  chain :to do |delegate|
    if delegate.is_a?(String) && delegate.include?("#")
      @delegate, @delegate_method = delegate.split "#"
    else
      @delegate = delegate
      @delegate_method = delegated_method
    end
  end

  chain :with do |delegate_params|
    @delegate_params = delegate_params
  end

  description do
    delegate_method = ("##{@delegate_method}" if delegated_method.to_s!=@delegate_method.to_s)
    delegate_params = (" with params #{@delegate_params.inspect}" if @delegate_params)
    "delegates #{delegated_method} to #{@delegate}#{delegate_method}#{delegate_params}"
  end

  failure_message_for_should do |text|
    "expected delegation of #{delegated_method} to #{@delegate}"
  end

  failure_message_for_should do |text|
    "do not expected delegation of #{delegated_method} to #{@delegate}"
  end
end
