require_relative 'pull_widget'

class BitcoinPrice < PullWidget

  def initialize(app_config)
    super
    @endpoint = 'https://api.coindesk.com/v1/bpi/currentprice/eur.json'
  end

  def update
    uri = URI.parse(@endpoint)
    data = JSON.parse(open(uri).read)
    {
      value_eur: data["bpi"]["EUR"]["rate_float"],
      value_usd: data["bpi"]["USD"]["rate_float"],
      last_update: Time.parse(data["time"]["updatedISO"]).iso8601
    }
  end
end