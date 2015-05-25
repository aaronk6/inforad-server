require_relative 'widget'

require 'open-uri'

class PullWidget < Widget

  def initialize(app_config)
    super

    @endpoint = nil
    @update_interval = 30
    @data = nil

    Thread.new do
      loop do
        log 'Updating... (next update in %s seconds)' % [ @update_interval ]
        begin
          @data = update
          log "Update successful"
        rescue Exception => e
          @data = { error: e.message }
          log "Update failed: %s" % e.message
        end
        addLastUpdateTimestamp
        sleep @update_interval
      end
    end

  end

  private

  def update
    raise NotImplementedError
  end

end
