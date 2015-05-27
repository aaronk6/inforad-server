require 'redis'
require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'yaml'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

WIDGET_PATH = __dir__ + '/widgets/'
Dir.glob(File.expand_path(WIDGET_PATH + "/*.rb", __FILE__)).each {|f| require f }

store = Redis.new

set :bind, '0.0.0.0'

set :allow_origin, :any
set :allow_methods, [:get, :options]
set :allow_credentials, false
set :max_age, "1728000"
set :expose_headers, ['Content-Type']

configure do
  enable :cross_origin
end

def enabled_widgets(store)
  enabled = JSON.parse(store.get("enabled_widgets")) rescue enabled = []
  enabled
end

get '/dashboard' do
  cross_origin
  content_type :json

  enabled = {}
  widget_data = {}

  # get data for all enabled widgets
  enabled_widgets(store).each do |name|
    begin
      widget_data[name] = JSON.parse(store.get("widget_%s" % name))
    rescue
      widget_data[name] = nil
    end
  end

  { dashboard: { items: widget_data } }.to_json
end

post '/widgets/*' do
  begin
    name = request.path.split('/')[-1]
  rescue
    status 400
    return ''
  end

  unless enabled_widgets(store).include? name
    status 404
    return ''
  end

  info = request.body.read.force_encoding("UTF-8")
  Object.const_get(name.camelize).new({}, store).update(info)

  status 204
  ''
end

options "*" do
  response.headers["Allow"] = "GET, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, Content-Type, Cache-Control, Accept"
  200
end
