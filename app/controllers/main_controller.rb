# frozen_string_literal: true
require 'http'
require_relative 'generic_controller'

class MainController < GenericController
  get '/' do
    content_type :json
    endpoints(solis_conf[:base_path]).to_json
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/:entity' do
    timing_start = Time.now
    content_type :json

    context = load_context
    context.from_cache=0
    Graphiti::with_context(context) do
      dump_by_content_type(for_resource.all(params.merge({ stats: { total: :count } })), @media_type) #.to_jsonapi
    end
  rescue Solis::Error::InvalidAttributeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid attribute', e.message, e)
  rescue Solis::Error::InvalidDatatypeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid datatype', e.message, e)
  rescue Graphiti::Errors::RecordNotFound
    content_type :json
    halt 404, api_error('404', request.url, 'Not found', "'#{id}' niet gevonden in  #{params[:entity]}")
  rescue StandardError => e
    puts e.backtrace.join("\n")
    content_type :json
    halt 500, api_error(response.status, request.url, "Error for '#{params[:entity]}", e.cause || e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  post '/:entity' do
    timing_start = Time.now
    content_type :json
    result = nil
    data = JSON.parse(request.body.read)
    data = data['attributes'] if data.include?('attributes')

    context = load_context
    context.from_cache=0
    Graphiti::with_context(context) do
      ids = []
      data = [data] unless data.is_a?(Array)
      data.each do |d|
        model = for_model.new(d)
        model.save(params.key?(:validate_dependencies) ? !params[:validate_dependencies].eql?('false') : true)
        ids << model.id
      end

      dump_by_content_type( for_resource.all({"filter":{"id":{"eq":"#{ids.join(',')}"}}}), @media_type )
    end
  rescue Graphiti::Errors::RecordNotFound
    content_type :json
    halt 404, api_error('404', request.url, 'Not found', "Niet gevonden in  #{params[:entity]} #{data.to_json}")
  rescue Solis::Error::InvalidAttributeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid attribute', e.message, e)
  rescue Solis::Error::InvalidDatatypeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid datatype', e.message, e)
  rescue StandardError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Unknown Error', e.cause || e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  get '/:entity/model' do
    timing_start = Time.now
    content_type :json
    if params.key?(:template) && params[:template]
      for_model.model_template.to_json
    else
      for_model.model.to_json
    end
  rescue Solis::Error::InvalidAttributeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid attribute', e.message, e)
  rescue Solis::Error::InvalidDatatypeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid datatype', e.message, e)
  rescue StandardError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Unknown Error', e.cause || e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  put '/:entity/:id' do
    timing_start = Time.now
    content_type :json
    result = {}
    context = load_context
    context.from_cache=0
    Graphiti::with_context(context) do
      resource = for_resource.find({ id: params['id'] })
      raise Graphiti::Errors::RecordNotFound unless resource

      data = JSON.parse(request.body.read)
      data = data['attributes'] if data.include?('attributes')
      data['id'] = params[:id] unless data.include?('id')

      resource = for_model.new.update(data,
                                      params.key?(:validate_dependencies) ? !params[:validate_dependencies].eql?('false') : true)

      result = for_resource.find({ id: resource.id })
      return result.to_jsonapi
    end
    result.to_jsonapi
  rescue Solis::Error::InvalidAttributeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid attribute', e.message, e)
  rescue Solis::Error::InvalidDatatypeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid datatype', e.message, e)
  rescue Graphiti::Errors::RecordNotFound
    content_type :json
    halt 404, api_error('404', request.url, 'Not found', "'#{id}' niet gevonden in  #{params[:entity]}")
  rescue StandardError => e
    content_type :json
    puts e.backtrace.join("\n")
    halt 500, api_error(response.status, request.url, 'Unknown Error', e.cause || e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  delete '/:entity/:id' do
    timing_start = Time.now
    content_type :json
    context = load_context
    context.from_cache=0
    Graphiti::with_context(context) do
      resource = for_resource.find({ id: params['id'] })
      raise Graphiti::Errors::RecordNotFound unless resource

      resource.data.destroy
      return resource.to_jsonapi
    end
    resource.to_jsonapi
  rescue Solis::Error::InvalidAttributeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid attribute', e.message, e)
  rescue Solis::Error::InvalidDatatypeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid datatype', e.message, e)
  rescue Graphiti::Errors::RecordNotFound
    content_type :json
    halt 404, api_error('404', request.url, 'Not found', "'#{id}' niet gevonden in  #{params[:entity]}")
  rescue StandardError => e
    content_type :json
    puts e.backtrace.join("\n")
    halt 500, api_error(response.status, request.url, 'Unknown Error', e.cause || e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  get '/:entity/:id' do
    timing_start = Time.now
    result = {}
    content_type :json
    id = params.delete(:id)
    context = load_context
    context.from_cache=0
    if params.key?('depth')
      depth = params[:depth].to_i
      depth = 1 if depth < 1
      data_logic_config = Solis::ConfigFile[:services][:data_logic]
      url = "#{data_logic_config[:host]}#{data_logic_config[:base_path]}graph?from_cache=0&language=#{context.language}&entity=#{params[:entity].classify}&id=#{id}&depth=#{depth}"
      begin
        response = HTTP.get(url)
        case response.code
        when 200
          result = JSON.parse(response.body)
        when 404
          raise Graphiti::Errors::RecordNotFound
        else
          halt 500, api_error(response.status, request.url, 'Unknown Error', e.cause || e.message, e)
        end
      rescue HTTP::ConnectionError => e
        halt 503, api_error(503, request.url, 'Service unavailable', e.cause || e.message, e)
      rescue StandardError => e
        halt 500, api_error(response.status, request.url, 'Unknown Error', e.cause || e.message, e)
      end
      result.to_json
    else
      Graphiti::with_context(context) do
        data = { id: id }
        data = data.merge(params)
        result = for_resource.find(data)
        dump_by_content_type(result, @media_type)
      end
    end
  rescue Solis::Error::InvalidAttributeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid attribute', e.message, e)
  rescue Solis::Error::InvalidDatatypeError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Invalid datatype', e.message, e)
  rescue Graphiti::Errors::RecordNotFound
    content_type :json
    halt 404, api_error('404', request.url, 'Not found', "'#{id}' niet gevonden in  #{params[:entity]}")
  rescue StandardError => e
    content_type :json
    halt 500, api_error(response.status, request.url, 'Unknown Error', e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end
end
