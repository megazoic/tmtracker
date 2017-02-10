# config.ru
require './tmapp'
#development
#HelloWorldApp.run! :port => 3000, :bind => '0.0.0.0'
#production
use Rack::ShowExceptions
run HelloWorldApp.new