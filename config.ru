# config.ru
require './tmapp'
HelloWorldApp.run! :port => 3000, :bind => '0.0.0.0'