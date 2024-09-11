require "sinatra"
require "sinatra/reloader"
require "http"
require "rspotify"
require "active_support/core_ext/string/inflections"



get("/") do
  erb(:home)
end

post("/process_city") do
  @user_input=params.fetch("city_input").downcase
  @user_location=""
  if @user_input.include?(" ")
    camelize_location=@user_input.gsub(" ", "_").camelize
    @location_formatted=camelize_location.titleize
    @user_location=@location_formatted
  else
    @user_location=@user_input.capitalize
  end

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
   @summary=summary_hash.fetch("summary").downcase
   @weather_summary=""
   if @summary.include?(" ")
    camelize_summary=@summary.gsub(" ", "_").camelize
    @summary_formatted=camelize_summary.titleize
    @weather_summary=@summary_formatted
  else
    @weather_summary=@summary.capitalize
  end

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

   #handle alerts when there aren't any
   alerts_data = pirate_weather_data.fetch("alerts", [])
    @alert = if alerts_data.any?
             alerts_data.first.fetch("title", "No alert title available.")
           else
             "No alerts available."
           end
  #-------------------------------------------------------------------------------------------------
  #USING A SPOTIFY WEB API RUBY WRAPPER: https://github.com/guilhermesad/rspotify
  
  client_id="9de1d0fc09d64f659e16a47ac87b2ca2"
  client_secret=ENV.fetch("SPOTIFY_TOKEN")
  RSpotify.authenticate(client_id, client_secret)

  if @precip != "none"
    @playlists = RSpotify::Playlist.search("#{@precipitation}weather")
  else
    if @summary== "clear"
      @playlists = RSpotify::Playlist.search("energetic")
  
    elsif @summary== "cloudy" 
      @playlists = RSpotify::Playlist.search("indie")
  
    elsif @summary== "partly cloudy" 
      @playlists = RSpotify::Playlist.search("chill")
  
    elsif @summary== "snow" 
      @playlists = RSpotify::Playlist.search("cozy")
  
    elsif @summary== "rain" 
      @playlists = RSpotify::Playlist.search("lofi")
    
    else 
      @playlists = RSpotify::Playlist.search("#{@sumarry} weather")

    end
  end

   erb(:process_city)
  
end
