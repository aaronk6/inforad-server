require './db_scraper'
require './bitcoin_price'
require './weather'
require './rain_forecast'

class Dashboard

  def initialize
    @items = {
      tram_schedule: DBScraper.new.getSchedule,
      bitcoin_price: BitcoinPrice.new.getBitcoinPrice,
      weather: Weather.new.getWeather,
      rain_forecast: RainForecast.new.getRainForecast
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