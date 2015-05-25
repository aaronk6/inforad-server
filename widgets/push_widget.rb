require_relative 'widget'

class PushWidget < Widget

  def update(data)
    addLastUpdateTimestamp
  end
end
