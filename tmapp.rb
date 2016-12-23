#tmapp.rb 
require 'sinatra'
require 'json'

class HelloWorldApp < Sinatra::Base
  get '/' do
    [200, {'Content-Type' => 'text/html', 'Connection' => 'close'}, ["hello world"]]
  end
end