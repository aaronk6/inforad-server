require 'net/http'
require 'net/https'
require 'uri'
require 'active_support/all'
require 'nokogiri'
require 'icalendar'

require_relative '../classes/push_widget'

class Report < Net::HTTPRequest
  METHOD = "REPORT"
  REQUEST_HAS_BODY = true
  RESPONSE_HAS_BODY = true
end

# FIXME: This needs cleanup. Move CalDAV related stuff to separate class.

class CurrentlyPlaying < PushWidget

  ICAL_DAY_TIME_FORMAT = "%Y%m%dT000000Z"

  def initialize(config, store)
    super

    @endpoint = nil
    @update_interval = 10

    # FIXME: Need a reliable way to figure out if we're currently receiving a push
    # or should do a pull
    if @config && @config["calendar"]

      Thread.new do
        loop do
          load_data_from_cache
          logger.info 'Updating... (next update in %s seconds)' % [ @update_interval ]

          events = get_events_in_range(Time.now - 1.day, Time.now.utc + 1.day)

          if current_event = events.detect {|e| event_has_begun? e}
            @data["calendar"] = "%s (%s - %s)" % [
              current_event ? current_event.summary : nil,
              Time.parse(current_event.dtstart.to_s).strftime('%H:%M'),
              Time.parse(current_event.dtend.to_s).strftime('%H:%M')
            ]
          else
            @data["calendar"] = nil
          end

          publish(@data)

          sleep @update_interval
        end
      end

    end

  end

  def get_events_in_range(start_time, end_time)
    conf = @config["calendar"]

    uri = URI.parse(conf["url"])

    start_time = start_time.strftime(ICAL_DAY_TIME_FORMAT)
    end_time = end_time.strftime(ICAL_DAY_TIME_FORMAT)

    query = %Q(
      <c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
        <d:prop>
          <d:getetag />
          <c:calendar-data />
        </d:prop>
        <c:filter>
          <c:comp-filter name="VCALENDAR">
            <c:comp-filter name="VEVENT">
              <c:time-range start="#{start_time}" end="#{end_time}"/>
            </c:comp-filter>
          </c:comp-filter>
        </c:filter>
      </c:calendar-query>
    )

    xml = make_caldav_request(uri, query, conf['username'], conf['password'])
    get_events_from_xml_response(xml)
  end

  def make_caldav_request (uri, query, username, password)
    begin
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'

      req = Report.new(uri.request_uri)
      req.basic_auth username, password
      req.body = query

      res = http.request(req)

      unless res.code.to_i == 207
        logger.warn "Calendar server error: #{res.code}, #{res.message}"
        return nil
      end

    rescue Exception => e
      logger.error "Error while trying to connect to calendar server: #{e.message}"
      return nil
    end

    res.body
  end

  def get_events_from_xml_response(xml_string)
    events = []
    begin
      ics = []
      Nokogiri::XML(xml_string).css('multistatus > response').each do |res|
        prop = res.css('propstat > prop')
        cdata_node = prop.children.detect {|n| n.name == 'calendar-data'}
        cdata = cdata_node.children.detect {|n| n.cdata?}
        events.push(Icalendar.parse(cdata.content).first.events.first)
      end
    rescue Exception => e
      logger.warn "Failed to parse response: #{e.message}"
    end
    events
  end

  def event_has_begun?(event)
    start_time = Time.parse event.dtstart.to_s
    end_time = Time.parse event.dtend.to_s
    (start_time..end_time).cover?(Time.now)
  end

  def update(info)
    @data["info"] = info.empty? ? nil : info
    publish(@data)
  end

end