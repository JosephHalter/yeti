require "spec_helper"

describe Yeti do
  it "version should be defined" do
    expect{ Yeti::VERSION }.not_to raise_error
  end
end
