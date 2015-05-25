require_relative 'push_widget'

class CurrentlyPlaying < PushWidget

  def initialize(app_config)
    super
  end

  def update(data)
    info = data.read.force_encoding('UTF-8')
    @data = { info: info.empty? ? nil : info }
    super
  end

end