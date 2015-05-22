class RainForecast

  ENDPOINT = 'http://www.wetteronline.de/'

  def initialize
    @config = YAML.load_file('config.yml')["rain_forecast"]
  end

  def getRainForecast
    uri = URI.parse(ENDPOINT)
    uri.query = URI.encode_www_form({
      ireq: "true",
      pid: "p_radar_map",
      src: "radar/vermarktung/p_radar_map_forecast/forecastLoop/%s/latestForecastLoop.gif" % [
        @config["federal_state"] ]
    })
    {
      federal_state: @config["federal_state"],
      animation_url: uri.to_s
    }
  end

end