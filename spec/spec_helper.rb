$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'comodule'
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each do |file|
  require file
end
Comodule::CustomizeClass.customize
