require 'uri'
require 'open-uri'
require 'json'

class BitcoinPrice

  SOURCE_URL = 'https://api.coindesk.com/v1/bpi/currentprice/eur.json'

  def getBitcoinPrice
    uri = URI.parse(SOURCE_URL)
    begin
      data = JSON.parse(open(uri).read)
    rescue Exception => e
      return {
        error: e.message,
        last_update: Time.now.iso8601
      }
    end
    {
      value_eur: data["bpi"]["EUR"]["rate_float"],
      value_usd: data["bpi"]["USD"]["rate_float"],
      last_update: Time.parse(data["time"]["updatedISO"]).iso8601
    }
  end
end