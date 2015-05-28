require 'sinatra'
require 'redis'
require 'faye/websocket'
require 'active_support/inflector'

require_relative 'classes/push_server'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

WIDGET_PATH = __dir__ + '/widgets/'
Dir.glob(File.expand_path(WIDGET_PATH + "/*.rb", __FILE__)).each {|f| require f }

set :bind, '0.0.0.0'

get '/' do

  if Faye::WebSocket.websocket?(request.env)
    PushServer.new.call(request.env)
  else
    status 400
    'Please connect using websocket. kthxbye'
  end
end

post '/widgets/*' do
  begin
    name = request.path.split('/')[-1]
  rescue
    status 400
    return ''
  end

  store = Redis.new
  enabled = JSON.parse(store.get("enabled_widgets")) rescue enabled = []

  unless enabled.include? name
    status 404
    return ''
  end

  info = request.body.read.force_encoding("UTF-8")
  Object.const_get(name.camelize).new({}, store).update(info)

  status 204
  ''
end
