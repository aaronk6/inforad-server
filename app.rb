require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'yaml'
require 'active_support/inflector'

Dir.glob(File.expand_path("../widgets/*.rb", __FILE__)).each {|f| require f }

AppState = {}

def bootstrap

  puts "Loading config"
  app_config = YAML.load_file('config.yml')

  puts "Loading widgets: %s" % app_config["enabled"].join(', ')
  widgets = {}
  app_config["enabled"].each do |name|
    widgets[name] = Object.const_get(name.camelize).new(app_config)
  end

  AppState["widgets"] = widgets
end

set :bind, '0.0.0.0'

set :allow_origin, :any
set :allow_methods, [:get, :options]
set :allow_credentials, false
set :max_age, "1728000"
set :expose_headers, ['Content-Type']

configure do
  enable :cross_origin
end

get '/dashboard' do
  cross_origin
  content_type :json
  items = {}
  AppState["widgets"].each do |name, widget|
    items[name] = widget.data
  end
  { dashboard: { items: items } }.to_json
end

post '/currently_playing' do
  # TODO: Make generic
  AppState["widgets"]["currently_playing"].update(request.body)
  status 204
  ''
end

options "*" do
  response.headers["Allow"] = "GET, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, Content-Type, Cache-Control, Accept"
  200
end

bootstrap