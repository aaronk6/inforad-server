require './db_scraper'
require './bitcoin_price'

class Dashboard

  def initialize
    @items = {
      tram_schedule: DBScraper.new.getSchedule,
      bitcoin_price: BitcoinPrice.new.getBitcoinPrice
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