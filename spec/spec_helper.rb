require "bundler/setup"
require "logger"
require "yeti"

RSpec.configure do |config|
  config.before(:all) do
    logger = Logger.new "test.log"
  end
end
