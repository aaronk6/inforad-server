require 'faye/websocket'
require 'em-hiredis'
require 'json'

require_relative 'logging'

class PushServer

  include Logging

  def call(env)
    ws = Faye::WebSocket.new(env)
    store = EM::Hiredis.connect

    setup_socket(store, ws)
    bootstrap(store, ws)
    subscribe(store, ws)

    # Return async Rack response
    ws.rack_response
  end

  def setup_socket(store, ws)

    ws.on :open do |event|
      store.incr("connection_count") do
        store.get("connection_count") do |value|
          logger.debug 'Client connected (connection count: %s)' % value
        end
      end
    end

    ws.on :close do |event|
      store.decr("connection_count") do
        store.get("connection_count") do |value|
          logger.debug 'Client disconnected (connection count: %s)' % value
        end
      end
      ws = nil
    end
  end

  def bootstrap(store, ws)

    # get list of enabled widgets
    store.get("enabled_widgets") do |value|
      begin
        enabled = JSON.parse(value)
      rescue
        enabled = []
      end
      logger.debug "Bootstrapping widgets: %s" % [ enabled.join(', ') ]

      # get cached data for each widget and push to client
      enabled.each do |name|
        store.get('widget_%s' % name) do |payload|
          ws.send(payload) if payload
        end
      end

    end
  end

  def subscribe(store, ws)

    store.pubsub.subscribe(:updates)

    store.pubsub.on(:message) do |ch, msg|
      ws.send(msg)
    end
  end

end