require_relative 'widget'

require 'open-uri'

class PullWidget < Widget

  def initialize(*args)
    super

    @endpoint = nil
    @update_interval = 30

    Thread.new do
      loop do
        logger.info 'Updating... (next update in %s seconds)' % [ @update_interval ]

        begin
          data = update
          logger.info "Update successful"
        rescue Exception => e
          data = { error: e.message }
          logger.warn "Update failed: %s" % e.message
        end

        @store.set("widget_%s" % name, add_last_update_timestamp(data).to_json)
        sleep @update_interval
      end
    end

  end

  private

  def update
    raise NotImplementedError
  end

end
