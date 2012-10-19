# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yeti/version'

Gem::Specification.new do |gem|
  gem.name          = "yeti"
  gem.version       = Yeti::VERSION
  gem.authors       = ["Joseph HALTER"]
  gem.email         = ["joseph@openhood.com"]
  gem.description   = %q{Yeti: Context, Editor and Search patterns}
  gem.summary       = %q{Editor pattern simplifies edition of multiple objects
                      at once using ActiveModel}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "activemodel"
  gem.add_runtime_dependency "string_cleaner"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
end
