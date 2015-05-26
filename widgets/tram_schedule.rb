require_relative '../classes/pull_widget'

require 'uri'
require 'open-uri'
require 'nokogiri'
require 'active_support/time'

class TramSchedule < PullWidget

  def initialize (*args)
    super

    @update_interval = 30
    @endpoint = "http://mobile.bahn.de/bin/mobil/bhftafel.exe/dox"
    @source_charset = "ISO-8859-1"
    @source_timezone = "CET"

  end

  private

  def update
    Time.zone = @source_timezone

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
    { schedule: schedule }
  end

  def getDoc
    uri = URI.parse(@endpoint)
    uri.query = URI.encode_www_form({
      si: @config["station"],
      max: @config["max_results"] || 10,
      bt: "dep",
      rt: 1,
      start: "yes"
    })
    logger.info "Getting data from %s" % uri.to_s
    doc = Nokogiri::HTML(open(uri), nil, @source_charset)
    doc.encoding = "UTF-8"
    doc
  end

end