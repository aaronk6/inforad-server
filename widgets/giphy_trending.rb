require_relative '../classes/pull_widget'

class GiphyTrending < PullWidget

  DEFAULT_API_KEY = 'dc6zaTOxFJmzC' # Giphy test key
  FORMAT_GIF = 'gif'
  FORMAT_MP4 = 'mp4'
  FORMAT_WEBP = 'webp'
  DEFAULT_FORMAT = FORMAT_GIF
  SUPPORTED_FORMATS = [ FORMAT_GIF, FORMAT_MP4, FORMAT_WEBP ]
  SUPPORTED_ITEM_TYPE = 'gif'
  MAX_RESULTS = 100 # 100 is Giphy's maximum (per request)

  def initialize(*args)
    super

    @endpoint = 'https://api.giphy.com/v1'
    @update_interval = 900
    @config["api_key"] = DEFAULT_API_KEY if not @config["api_key"]
    if not @config["format"] or not SUPPORTED_FORMATS.include? @config["format"]
      @config["format"] = DEFAULT_FORMAT
    end
  end

  private

  def update
    res = queryAPI('gifs/trending')
    data = JSON.load(res)["data"]

    items = []
    data.each do |i|
      next if i["type"] != SUPPORTED_ITEM_TYPE
      item = {
        id: i["id"]
      }
      case @config["format"]
      when FORMAT_GIF
        item[:url] = i["images"]["fixed_height"]["url"]
      when FORMAT_MP4
        item[:url] = i["images"]["fixed_height"]["mp4"]
      when FORMAT_WEBP
        item[:url] = i["images"]["fixed_height"]["webp"]
      end
      next if not item[:url] or item[:url] == ""
      items.push item
    end

    {
      format: @config["format"],
      items: items || []
    }
  end

  def queryAPI(route, limit=MAX_RESULTS)
    uri = URI.parse("%s/%s" % [ @endpoint, route ])
    uri.query = URI.encode_www_form({
      api_key: @config["api_key"],
      limit: limit
    })
    logger.info "Getting data from %s" % uri.to_s
    open(uri).read
  end

end