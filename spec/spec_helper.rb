$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'itunes/receipt'
require 'rspec'
require 'helpers/fake_json_helper'

def sandbox_mode(&block)
  Itunes.sandbox!
  yield
ensure
  Itunes.sandbox = false
end
