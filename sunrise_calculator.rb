require "faraday"
require "json"
require "time"
require "yaml"

SETTINGS_FILE = File.expand_path("../settings.yml", __FILE__)
SETTINGS = YAML.load_file(SETTINGS_FILE)
LATITUDE = SETTINGS["coordinates"]["latitude"]
LONGITUDE = SETTINGS["coordinates"]["longitude"]
TIMEZONE = SETTINGS["times"]["timezone"]
SUNRISE_API = "http://api.sunrise-sunset.org"
SUNRISE_CLIENT = Faraday.new(SUNRISE_API)

class Time
   require 'tzinfo'
   def in_timezone tzstring
    tz = TZInfo::Timezone.get tzstring
    period = tz.period_for_utc self
    new_time = self + period.utc_total_offset
    "#{new_time.strftime("%I:%M %p")} #{period.zone_identifier}"
   end
 end

sunrise_response = SUNRISE_CLIENT.get("/json?lat=#{LATITUDE}&lng=#{LONGITUDE}&date=today")
sunrise_data = JSON.parse sunrise_response.body

utc_sunrise = sunrise_data["results"]["sunrise"]
utc_sunset = sunrise_data["results"]["sunset"]

local_sunrise = Time.parse(utc_sunrise + " UTC").in_timezone(TIMEZONE)
local_sunset = Time.parse(utc_sunset + " UTC").in_timezone(TIMEZONE)

SETTINGS["times"]["sunrise"] = local_sunrise
SETTINGS["times"]["sunset"] = local_sunset

file = File.open(SETTINGS_FILE, 'w')
file.write SETTINGS.to_yaml
file.close
