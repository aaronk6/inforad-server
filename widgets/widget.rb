require 'yaml'
require 'uri'
require 'open-uri'

class Widget

  attr_reader :data

  def initialize(app_config)
    puts "Initializing %s" % name

    @config = {}

    if (widget_conf = app_config["widget_config"])
      @config = widget_conf[name] if widget_conf[name]
    end
  end

  def name
    self.class.name.underscore
  end

  def log(msg)
    puts "[%s] %s" % [ name, msg ]
  end

  def addLastUpdateTimestamp
    @data[:last_update] = Time.now.iso8601 if not @data[:last_update]
  end

end