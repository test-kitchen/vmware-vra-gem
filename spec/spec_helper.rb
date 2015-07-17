require 'vra'
require 'webmock/rspec'

RSpec.configure do |c|
  c.before(:each) do
    @vra = Vra::Client.new(username: 'user@corp.local',
                           password: 'password',
                           tenant: 'tenant',
                           base_url: 'https://vra.corp.local')
  end
end

WebMock.disable_net_connect!(allow_localhost: true)
