require 'sinatra'
require 'sinatra/cross_origin'
require 'json'

require './dashboard'

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
  Dashboard.new.getDashboard.to_json
end

options "*" do
  response.headers["Allow"] = "GET, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, Content-Type, Cache-Control, Accept"
  200
end