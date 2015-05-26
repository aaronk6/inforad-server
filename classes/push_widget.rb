require_relative 'widget'

class PushWidget < Widget

  def update(info)
    data = { info: info.empty? ? nil : info }
    @store.set("widget_%s" % name, add_last_update_timestamp(data).to_json)
  end

end
