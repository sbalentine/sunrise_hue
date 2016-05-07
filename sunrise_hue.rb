require "faraday"
require "json"
require "time"
require "yaml"

SETTINGS_FILE = File.expand_path "../settings.yml", __FILE__
SETTINGS = YAML.load_file SETTINGS_FILE
HUE_USERNAME = SETTINGS["hue"]["username"]
HUE_LIGHT_IDS = SETTINGS["hue"]["light_ids"]

def sunrise_soon?
  sunrise = Time.parse SETTINGS["times"]["sunrise"]
  (sunrise - Time.now).between? 0, 120
end

def sunset_soon?
  sunset = Time.parse SETTINGS["times"]["sunset"]
  (sunset - Time.now).between? 0, 120
end

def change_state(state)
  HUE_LIGHT_IDS.each do |hue_id|
    hue_client.put "/api/#{HUE_USERNAME}/lights/#{hue_id}/state", JSON.generate(on: state)
  end
end

def hue_client
  internal_api = Faraday.new "https://www.meethue.com/api/nupnp"
  hue_ip = JSON.parse(internal_api.get.body)[0]["internalipaddress"]
  Faraday.new "http://#{hue_ip}"
end

while true
  now = Time.now
  sunset = Time.parse SETTINGS["times"]["sunset"]
  if sunrise_soon?
    change_state false
  end
  if sunset_soon?
    change_state true
  end
  sleep 60
end
