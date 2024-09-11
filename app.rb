require "sinatra"
require "sinatra/reloader"

get("/") do
  erb(:home)
end

get("/process_city") do
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
   @current_temp = weather_hash.fetch("temperature")
  

   #summary information
   summary_hash = pirate_weather_data.fetch("hourly")
   @summary=summary_hash.fetch("summary")

  #precipation
  hourly_hash = pirate_weather_data.fetch("hourly")
  hourly_data_array = hourly_hash.fetch("data") 
  data_array_hash=hourly_data_array[0]
  @precipitation=data_array_hash.fetch("precipType")

   erb(:process_city)
end
