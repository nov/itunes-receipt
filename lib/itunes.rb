require 'json'
require 'active_support/core_ext'
require 'restclient_with_cert'

module Itunes

  ENDPOINT = {
    :production => 'https://buy.itunes.apple.com/verifyReceipt',
    :sandbox => 'https://sandbox.itunes.apple.com/verifyReceipt'
  }

  def self.endpoint
    ENDPOINT[itunes_env]
  end

  def self.itunes_env
    sandbox? ? :sandbox : :production
  end

  def self.sandbox?
    @@sandbox
  end
  def self.sandbox!
    self.sandbox = true
  end
  def self.sandbox=(boolean)
    @@sandbox = boolean
  end
  self.sandbox = false

  def self.shared_secret
    @@shared_secret
  end
  def self.shared_secret=(shared_secret)
    @@shared_secret = shared_secret
  end
  self.shared_secret = nil

end
