require_relative 'widget'

class PushWidget < Widget

  def update(info)
    publish({ info: info.empty? ? nil : info })
  end

end
