require_relative 'pull_widget'

class RainForecast < PullWidget

  def initialize(app_config)
    super

    @endpoint = 'http://www.wetteronline.de/'
  end

  def update
    uri = URI.parse(@endpoint)
    uri.query = URI.encode_www_form({
      ireq: "true",
      pid: "p_radar_map",
      src: "radar/vermarktung/p_radar_map_forecast/forecastLoop/%s/latestForecastLoop.gif" % [
        @config["federal_state"] ],
      "_": Time.new.to_i
    })
    {
      federal_state: @config["federal_state"],
      animation_url: uri.to_s
    }
  end

end