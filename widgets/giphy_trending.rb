require_relative '../classes/pull_widget'

class GiphyTrending < PullWidget

  DEFAULT_API_KEY = 'dc6zaTOxFJmzC' # Giphy test key
  SUPPORTED_ITEM_TYPE = 'gif'
  MAX_RESULTS = 100 # 100 per request is Giphy's maximum

  def initialize(*args)
    super

    @endpoint = 'https://api.giphy.com/v1'
    @update_interval = 300
    @config["api_key"] = DEFAULT_API_KEY if not @config["api_key"]
  end

  private

  def update
    res = queryAPI('gifs/trending')
    data = JSON.load(res)["data"]

    items = []
    data.each do |item|
      next if item["type"] != SUPPORTED_ITEM_TYPE
      items.push({
        id: item["id"],
        url: item["images"]["fixed_height"]["url"]
      })
    end

    {
      items: items
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