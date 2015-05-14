require './db_scraper'
require './bitcoin_price'
require './weather'

class Dashboard

  def initialize
    @items = {
      tram_schedule: DBScraper.new.getSchedule,
      bitcoin_price: BitcoinPrice.new.getBitcoinPrice,
      weather: Weather.new.getWeather
    }
  end

  def getDashboard
    {
      dashboard: {
        items: @items
      }
    }
  end
end