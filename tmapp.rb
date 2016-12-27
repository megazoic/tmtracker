#tmapp.rb 
require 'sinatra'
require 'json'
require 'net/http'
require 'logger'

logger = Logger.new('tmtracker.log', 10, 1024000)
logger.level = Logger::DEBUG

class HelloWorldApp < Sinatra::Base
  get '/:stop/:key' do
    uAIFarray = Array.new
    urlAppIdFile = File.open("testMisc.txt")
    urlAppIdFile.each_line do |line|
      uAIFarray << line.chomp
    end
    if uAIFarray[2] != params['key']
      #get out of here
      halt 401, "you have not submitted correct credentials"
    end
    # get data
    outString = ''
    begin
      url = URI("https://#{uAIFarray[0]}/ws/v2/arrivals?locIDs=#{params['stop']}&json=true&minutes=30&appID=#{uAIFarray[1]}")
      response = Net::HTTP.get_response(url)
    rescue
      halt 503, "API not responding"
      #log error here
    end
    if response.code == "200"
      outString = response.body
    else
      #log error here
      #send notice
      halt 502, "API responded incorrectly"
    end
      
    tmData = JSON.parse(outString)
    # build returnHash for next two buses
    currentTime = Time.new
    returnHash = Hash.new
    records = tmData["resultSet"]["arrival"].length
    #get routes
    routes = Array.new
    (0..records-1).each{|n|
      routes << tmData["resultSet"]["arrival"][n]["route"].to_s
    }
    routes.uniq!
    routes.each{|route|
      returnHash[route] = []
    }
    #build hash with route and arrival times
    (0..records-1).each{|n|
      errorStatus = ''
      arriveTime = ''
      route = tmData["resultSet"]["arrival"][n]["route"].to_s
      if (tmData["resultSet"]["arrival"][n].has_key?("trackingError"))
        nextTime = Time.at(tmData["resultSet"]["arrival"][n]["scheduled"].to_s[0..9].to_i)
        errorStatus = "1"
      else
        nextTime = Time.at((tmData["resultSet"]["arrival"][n]["estimated"].to_s[0..9]).to_i)
        errorStatus = "0"
      end
      arriveTime = ((nextTime - currentTime)/60).to_i.to_s
      returnHash[route] << "#{errorStatus},#{arriveTime}"
    }
    #get in ascending order of time from now and keep closest two entries
    re = /,([0-9]+)/
    routes.each{|route|
      begin
        returnHash[route].sort_by! {|arrival| re.match(arrival)[1].to_i}
        returnHash[route] = returnHash[route][0..1]
      rescue => err
        logger.debug("Can't sort hash:\n#{returnHash(route)}\nError:\n#{err}")
      end
    }
    [200, {'Content-Type' => 'text/html', 'Connection' => 'close'}, "#{returnHash}"]
  end
  get '/' do
    halt 403
  end
end