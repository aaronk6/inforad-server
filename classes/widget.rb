require 'json'
require 'yaml'
require 'uri'
require 'open-uri'

require_relative 'logging'

class Widget

  include Logging

  def initialize(config, store)
    @config = config
    @store = store

    load_data_from_cache
  end

  def load_data_from_cache
    begin
      @data = JSON.parse(@store.get("widget_%s" % name))["widget"]["data"] || {}
    rescue Exception => e
      @data = {}
    end
  end

  def name
    self.class.name.underscore
  end

  def add_last_update_timestamp(data)
    data["last_update"] = Time.now.iso8601 if not data["last_update"]
    data
  end

  def publish(data)
    payload = { "widget": {
        "name": name,
        "data": add_last_update_timestamp(data)
      } }.to_json

    @store.set("widget_%s" % name, payload)
    @store.publish(:updates, payload)
  end

end