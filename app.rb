require "sinatra"
require "sinatra/reloader"
require "http"
require "rspotify"

get("/") do
  erb(:home)
end

post("/process_city") do
  @user_input=params.fetch("city_input").downcase

   #location information
   access_gmaps_key = ENV.fetch("GMAPS_KEY")
   @gmaps_location= HTTP.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{@user_input}&key=#{access_gmaps_key}")
   @location_data=JSON.parse(@gmaps_location)
   @location_hash=@location_data.fetch("results").at(0)
   @geometry_hash=@location_hash.fetch("geometry")
   @lat=@geometry_hash.fetch("location").fetch("lat")
   @lng=@geometry_hash.fetch("location").fetch("lng")
 
   #weather information
   pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
   pirate_weather_url = HTTP.get("https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{@lat},#{@lng}")
   pirate_weather_data = JSON.parse(pirate_weather_url)
   weather_hash = pirate_weather_data.fetch("currently")
   @current_temp = weather_hash.fetch("temperature").to_i

   #summary information
   summary_hash = pirate_weather_data.fetch("hourly")
   @summary=summary_hash.fetch("summary")

  #precipitation
   hourly_hash = pirate_weather_data.fetch("hourly")
   hourly_data_array = hourly_hash.fetch("data") 
   data_array_hash=hourly_data_array[0]
   @precip=data_array_hash.fetch("precipType")
   @precipitation=""
   if data_array_hash.fetch("precipType") == "none"
    @precipitation= "No precipitation at this time."
   else
    @precipitation= data_array_hash.fetch("precipType")
   end

   #alerts
   alert_data=pirate_weather_data.fetch("alerts")
   alert_hash=alert_data[0]
   @alert=""

   #handle alerts when there aren't any
   if pirate_weather_data && pirate_weather_data.key?("alerts")
    alert_data = pirate_weather_data.fetch("alerts")
    if alert_data.any?
      @alert = alert_hash.fetch("title", "No alert title available.")
    else
      @alert = "No alerts available."
    end
   else
    @alert = "No alerts data."
  end
  #-------------------------------------------------------------------------------------------------
  #USING A SPOTIFY WEB API RUBY WRAPPER: https://github.com/guilhermesad/rspotify
  
  client_id="9de1d0fc09d64f659e16a47ac87b2ca2"
  client_secret=ENV.fetch("SPOTIFY_TOKEN")
  RSpotify.authenticate(client_id, client_secret)

  if @precipitation != "none"
    @playlists = RSpotify::Playlist.search("#{@precipitation}weather")
  else
    if @summary.downcase== "clear"
      @playlists = RSpotify::Playlist.search("upbeat")
  
    elsif @summary.downcase== "cloudy" 
      @playlists = RSpotify::Playlist.search("indie")
  
    elsif @summary.downcase== "partly cloudy" 
      @playlists = RSpotify::Playlist.search("chill")
  
    elsif @summary.downcase== "snow" 
      @playlists = RSpotify::Playlist.search("cozy")
  
    elsif @summary.downcase== "rain" 
      @playlists = RSpotify::Playlist.search("lofi")
    
    else 
      @playlists = RSpotify::Playlist.search("#{@sumarry} weather")

    end
  end

   erb(:process_city)
  
end
