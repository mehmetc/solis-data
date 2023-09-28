require 'active_support/all'
require 'sinatra/base'
require 'http/accept'
require 'solis'
require 'lib/file_queue'
require 'app/helpers/main_helper'

require solis_conf[:hooks] if solis_conf.key?(:hooks) && File.exist?(solis_conf[:hooks])

class GenericController < Sinatra::Base
  helpers Sinatra::MainHelper

  DATA_QUEUE = FileQueue.new(Solis::ConfigFile[:name], base_dir: Solis::ConfigFile[:events])
  SOLIS_CONF = solis_conf.key?(:hooks) && File.exist?(solis_conf[:hooks]) ? solis_conf.merge(Solis::HooksHelper.hooks(DATA_QUEUE)) : solis_conf

  configure do
    mime_type :jsonapi, 'application/vnd.api+json'
    set :method_override, true # make a PUT, DELETE possible with the _method parameter
    set :show_exceptions, false
    set :raise_errors, false
    set :root, File.absolute_path("#{File.dirname(__FILE__)}/../../")
    set :views, (proc { "#{root}/app/views" })
    set :logging, true
    set :static, true
    set :public_folder, "#{root}/public"
    set :role, ENV['SERVICE_ROLE']
    set :cache, Moneta.new(:File, dir: Solis::ConfigFile[:cache], expires: (Solis::ConfigFile[:cache_expire] || 86400))

    set :solis, Solis::Graph.new(Solis::Shape::Reader::File.read(solis_conf[:shape]),
                                       SOLIS_CONF)
  end

  before do
    accept_header = request.env['HTTP_ACCEPT']
    accept_header = params['accept'] if params.include?('accept')
    accept_header = 'application/json' if accept_header.nil?

    media_types = HTTP::Accept::MediaTypes.parse(accept_header).map { |m| m.mime_type.eql?('*/*') ? 'application/json' : m.mime_type } || ['application/json']
    @media_type = media_types.first

    if @media_type.eql?('text/html')
      @media_type = 'application/json'
    end

    content_type @media_type
  end

  get '/' do
    halt '404', 'To be implemented'
  end

  not_found do
    content_type :json
    message = body
    logger.error(message)
    message
  end

  error do
    content_type :json
    message = { status: 500, body: "error:  #{env['sinatra.error'].to_s}" }
    logger.error(message)
    message
  end
end