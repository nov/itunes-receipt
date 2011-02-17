require 'fakeweb'

module FakeJsonHelper

  def fake_json(expected, options = {})
    FakeWeb.register_uri(
      :post,
      Itunes.endpoint,
      options.merge(
        :body => File.read(File.join(File.dirname(__FILE__), '../fake_json', "#{expected}.json"))
      )
    )
  end

  def post_to(endpoint)
    raise_error(
      FakeWeb::NetConnectNotAllowedError,
      "Real HTTP connections are disabled. Unregistered request: POST #{endpoint}"
    )
  end

end

FakeWeb.allow_net_connect = false
include FakeJsonHelper