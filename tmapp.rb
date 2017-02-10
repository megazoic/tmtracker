#tmapp.rb 
require 'sinatra'
require 'json'
require 'net/http'
#require 'logger'

#logger = Logger.new('tmtracker.log', 10, 1024000)
#logger.level = Logger::DEBUG

class HelloWorldApp < Sinatra::Base
  # :type is 'A' Arrivals, 'P' position. For now only interested in arrivals so no test of symbol
  get ':type/:stop/:key' do
    if :type == 'A' then
      uAIFarray = Array.new
      urlAppIdFile = File.open("config/credentials.txt")
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
        url = URI("https://#{uAIFarray[0]}/ws/v2/arrivals?locIDs=#{params['stop']}&json=true&minutes=40&appID=#{uAIFarray[1]}")
        response = Net::HTTP.get_response(url)
      rescue
        halt 503, "API not responding"
        #log error here
        #logger.debug("503 error\n")
      end
      if response.code == "200"
        outString = response.body
      else
        #log error here
        #send notice
        halt 502, "API responded incorrectly"
        #logger.debug("502 error\n")
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
      #add time to the hash
      returnHash["Time"] = currentTime.strftime("%H%M")
      #build hash with route and arrival times
      (0..records-1).each{|n|
        errorStatus = 0
        arriveTime = 0
        route = tmData["resultSet"]["arrival"][n]["route"].to_s
        if (tmData["resultSet"]["arrival"][n].has_key?("trackingError"))
          nextTime = Time.at(tmData["resultSet"]["arrival"][n]["scheduled"].to_s[0..9].to_i)
          errorStatus = 1
        else
          nextTime = Time.at((tmData["resultSet"]["arrival"][n]["estimated"].to_s[0..9]).to_i)
          errorStatus = 0
        end
        arriveTime = ((nextTime - currentTime)/60).to_i
        #returnHash[route] << "#{errorStatus},#{arriveTime}"
        returnHash[route] << [errorStatus,arriveTime]
      }
      #get in ascending order of time from now and keep closest two entries
      #re = /,([0-9]+)/
      hashOut = Hash.new
      routes.each{|route|
        begin
          #these don't work now that value of hash is in 2D array
          #returnHash[route].sort_by! {|arrival| re.match(arrival)[1]}
          #returnHash[route] = returnHash[route][0..1]
          hashOut[route] = returnHash[route][0..1]
        rescue => err
          #logger.debug("Can't sort hash:\n#{returnHash[route]}\nError:\n#{err}\n")
        end
      }
      hashOut["Time"] = returnHash["Time"]
      responseString = hashOut.to_json
      [200, {'Content-Type' => 'application/json', 'Connection' => 'close'}, "#{responseString}"]
    end
  end
  get '/staticArray' do
    response = "{\"75\":[[0,4],[1,18]],\"17\":[[0,6],[1,48]],\"Time\":\"1935\"}"
    [200, {'Content-Type' => 'application/json', 'Connection' => 'close'}, "#{response}"]
  end
  get '/test' do
    testHash = Hash.new
    testHash["75"] = [0,10]
    testHash["Time"] = "0932"
    [200, {'Content-Type' => 'application/json', 'Connection' => 'close'}, "#{testHash.to_json}"]
  end
  get '/' do
    halt 403
  end
end