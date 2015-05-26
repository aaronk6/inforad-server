require_relative '../classes/pull_widget'

class Weather < PullWidget

  DEFAULT_LANG = 'EN'

  def initialize(*args)
    super

    @endpoint = 'http://api.wunderground.com/api'
    @update_interval = 300
    @config["lang"] = DEFAULT_LANG if not @config["lang"]
  end

  private

  def update
    res = queryAPI('/conditions/lang:%s/q/%s' % [
      @config["lang"], URI::encode(@config["station_id"])])

    data = JSON.load(res)["current_observation"]

    {
      observation_location: data["observation_location"]["city"],
      observation_time: Time.parse(data["observation_time_rfc822"]).iso8601,
      weather: data["weather"],
      temp_c: data["temp_c"],
      relative_humidity: data["relative_humidity"],
      wind_dir: data["wind_dir"],
      wind_degrees: data["wind_degrees"],
      wind_kph: data["wind_kph"],
      icon: data["icon"]
    }
  end

  def queryAPI(route)
    uri = URI.parse("%s/%s/%s.json" % [ @endpoint, @config["api_key"], route ])
    logger.info "Getting data from %s" % uri.to_s
    open(uri).read
  end

end