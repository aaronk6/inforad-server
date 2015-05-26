require 'redis'
require 'yaml'
require 'active_support/inflector'

require_relative 'logging'

class Updater

  include Logging

  CONFIG_PATH = __dir__ + '/../config.yml'
  WIDGET_PATH = __dir__ + '/../widgets/'

  def initialize
    @store = Redis.new

    return unless load_config && load_widgets

    # write list of enabled widgets to store
    @store.set("enabled_widgets", @widgets.keys.to_json)

    puts "store: %s" % @store.inspect

    begin
      sleep
    rescue Interrupt
      puts "\nBye."
    end
  end

  private

  def load_config
    logger.info "Loading config"
    begin
      @config = YAML.load_file(CONFIG_PATH)
    rescue
      logger.error "Failed to load config"
      return false
    end

    unless @config["enabled"] && @config["enabled"].kind_of?(Array)
      logger.error "Please enable the desired modules in the config file " +
        "(see config.yml.example)"
      return false
    end
    true
  end

  def load_widgets
    logger.info "Loading widgets (%s)" % @config["enabled"].join(', ')
    @widgets = {}

    Dir.glob(File.expand_path(WIDGET_PATH + "/*.rb", __FILE__)).each {|f| require f }
    @config["enabled"].each do |name|
      widget_config = {}
      if @config["widget_config"] && @config["widget_config"][name]
        widget_config = @config["widget_config"][name]
      end
      @widgets[name] = Object.const_get(name.camelize).new(widget_config, @store)
    end
    true
  end

end
