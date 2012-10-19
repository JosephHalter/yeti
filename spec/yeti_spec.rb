require "spec_helper"

describe Yeti do
  it "version should be defined" do
    lambda{ Yeti::VERSION }.should_not raise_error NameError
  end
end
