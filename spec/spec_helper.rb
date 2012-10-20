require "bundler/setup"
require "logger"
require "yeti"
require "support/matchers"

RSpec.configure do |config|
  config.before(:all) do
    logger = Logger.new "test.log"
  end
end
