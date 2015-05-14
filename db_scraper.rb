require 'rubygems'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'yaml'
require 'active_support/time'

class DBScraper

  SOURCE_URL = "http://mobile.bahn.de/bin/mobil/bhftafel.exe/dox"
  SOURCE_CHARSET = "ISO-8859-1"
  SOURCE_TIMEZONE = "CET"

  def initialize
    @config = YAML.load_file('config.yml')["db_scraper"]
  end

  def getSchedule
    Time.zone = SOURCE_TIMEZONE

    doc = getDoc
    items = doc.css('#content .clicktable .trow');
    now = Time.now

    schedule = []
    departure = nil

    items.each do |item|

      train = item.css("> a > span").text().squeeze(" ").strip
      departure = Time.zone.parse(item.css("> span.bold").text())
      destination = /\>\>\n([^,\(]*)?/m.match(item.text())[1].strip
      normal_delay = item.css("> span.okmsg").text().sub!(/^\+/, "").to_i
      heavy_delay = item.css("> span.red").text().sub!(/^\+/, "").to_i
      delay = normal_delay + heavy_delay

      # remove train prefix if necessary (e.g. "STR N10" -> "N10")
      if (prefix = @config["remove_train_prefix"])
        train.slice!(prefix)
      end

      # if departure time is more than 12 hours in the past, assume it's on the next day
      departure += 60 * 60 * 24 if departure < now - 60 * 60 * 12

      schedule.push({
        train: train,
        departure: departure.iso8601,
        destination: destination,
        delay: delay
      })
    end
    {
      schedule: schedule,
      last_update: Time.now.iso8601
    }
  end

  private

  def getDoc
    uri = URI.parse(SOURCE_URL)
    uri.query = URI.encode_www_form({
      si: @config["station"],
      max: @config["max_results"] || 10,
      bt: "dep",
      rt: 1,
      start: "yes"
    })
    doc = Nokogiri::HTML(open(uri), nil, SOURCE_CHARSET)
    doc.encoding = "UTF-8"
    doc
  end
end