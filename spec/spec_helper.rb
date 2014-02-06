require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

require 'rspec'
require 'itunes/receipt'
require 'helpers/fake_json_helper'

def sandbox_mode(&block)
  Itunes.sandbox!
  yield
ensure
  Itunes.sandbox = false
end
