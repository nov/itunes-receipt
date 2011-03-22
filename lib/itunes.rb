require 'json'
require 'active_support/core_ext'
require 'restclient_with_cert'

module Itunes

  ENDPOINT = {
    :production => 'https://buy.itunes.apple.com/verifyReceipt',
    :sandbox => 'https://sandbox.itunes.apple.com/verifyReceipt'
  }

  def self.endpoint
    if sandbox?
      ENDPOINT[:sandbox]
    else
      ENDPOINT[:production]
    end
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

end