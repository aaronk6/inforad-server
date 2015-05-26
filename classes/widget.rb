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
  end

  def name
    self.class.name.underscore
  end

  def add_last_update_timestamp(data)
    data[:last_update] = Time.now.iso8601 if not data[:last_update]
    data
  end

end