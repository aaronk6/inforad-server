require 'logger'
require 'open-uri'
require 'digest/sha1'
require 'json'

class Weather

  ENDPOINT = 'http://api.wunderground.com/api'
  DEFAULT_LANG = 'EN'
  DEFAULT_CACHE_DURATION = 300

  @@cache = {}

  def initialize
    @config = YAML.load_file('config.yml')["weather"]
    @config["lang"] = @config["lang"] || DEFAULT_LANG
    @config["cache_duration"] = @config["cache_duration"] || DEFAULT_CACHE_DURATION
  end

  def getWeather
    begin
      res = queryAPI('/conditions/lang:%s/q/%s' % [
        @config["lang"], URI::encode(@config["station_id"])])
    rescue Exception => e
      return {
        error: e.message,
        last_update: Time.now.iso8601
      }
    end

    data = JSON.load(res[:data])["current_observation"]
    {
      observation_location: data["observation_location"]["city"],
      observation_time: Time.parse(data["observation_time_rfc822"]).iso8601,
      weather: data["weather"],
      temp_c: data["temp_c"],
      relative_humidity: data["relative_humidity"],
      wind_dir: data["wind_dir"],
      wind_degrees: data["wind_degrees"],
      wind_kph: data["wind_kph"],
      icon: data["icon"],
      hit_cache: res[:hit_cache],
      last_update: Time.now.iso8601
    }
  end

  private

  def queryAPI(route)
    uri = URI.parse("%s/%s/%s.json" % [ ENDPOINT, @config["api_key"], route ])
    hit_cache = false

    if (res = tryToGetFromCache(uri))
      hit_cache = true
    else
      res = open(uri).read
      cacheResult(uri, res)
    end

    return {
      hit_cache: hit_cache,
      data: res
    }
  end

  def tryToGetFromCache(uri)
    item = @@cache[generateCacheID(uri)]
    if item && Time.now.to_i - item[:created].to_i < @config["cache_duration"]
      return item[:data]
    end
    nil
  end

  def cacheResult(uri, res)
    @@cache[generateCacheID(uri)] = {
      created: Time.now,
      data: res
    }
  end

  def generateCacheID(uri)
    Digest::SHA1.hexdigest(uri.to_s)
  end

end