# encoding: utf-8
$LOAD_PATH << '.'
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'solis'
require 'rack/cors'
require 'app/controllers/main_controller'

raise 'Please set SERVICE_ROLE environment parameter' unless ENV.include?('SERVICE_ROLE')
$SERVICE_ROLE=ENV['SERVICE_ROLE'].downcase.to_sym
puts "setting SERVICE_ROLE=#{$SERVICE_ROLE}"

map "#{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}" do
  Solis::LOGGER.info("Mounting 'MainController' on #{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}")
  run MainController
end
