require 'json'
require 'jwt'
require 'stopwords'
require 'solis/store/sparql/client'

def solis_conf
  raise 'Please set SERVICE_ROLE environment parameter' unless ENV.include?('SERVICE_ROLE')
  Solis::ConfigFile[:services][ENV['SERVICE_ROLE'].to_sym][:solis]
end

module Sinatra
  module MainHelper
    def endpoints(base_path=solis_conf[:base_path])
      settings.solis.list_shapes.map {|m| "#{base_path}#{m.tableize}"}.sort
    end

    def api_error(status, source, title="Unknown error", detail="", e = nil)
      content_type :json

      puts e.backtrace.join("\n") unless e.nil?

      message = {"errors": [{
                    "status": status,
                    "source": {"pointer":  source},
                    "title": title,
                    "detail": detail
                  }]}.to_json
    end

    def for_resource
      entity = params[:entity]
      halt 404, api_error('404', request.url, "Not found", "Available endpoints: #{endpoints.join(', ')}") if endpoints.grep(/#{entity}/).empty?
      klass="#{entity.singularize.classify}"
      settings.solis.shape_as_resource(klass)
    end

    def for_model
      entity = params[:entity]
      halt 404, api_error('404', request.url, "Not found", "Available endpoints: #{endpoints.join(', ')}") if endpoints.grep(/#{entity}/).empty?
      klass="#{entity.singularize.classify}"
      settings.solis.shape_as_model(klass)
    end

    def recursive_compact(hash_or_array)
      p = proc do |*args|
        v = args.last
        v.delete_if(&p) if v.respond_to? :delete_if
        v.nil? || v.respond_to?(:"empty?") && v.empty?
      end

      hash_or_array.delete_if(&p)
    end

    def load_context
      id = '0'
      other_data = {}
      if request.has_header?('HTTP_X_FRONTEND')
        data = request.get_header('HTTP_X_FRONTEND')
        halt 500, api_error('400', request.url, 'Error parsing header X-Frontend', 'Error parsing header X-Frontend') if data.nil? || data.empty?
        data = data.split(';').map{|m| m.split('=')}
        data = data.map{|m| m.length == 1 ? m << '' : m}

        data = data&.to_h

        halt 500, api_error('400', request.url, 'Error parsing header X-Frontend', 'Header must include key/value id=1234567') unless data.key?('id')

        id = data.key?('id') ? data['id'] : '0'
        group = data.key?('group') ? data['group'] : '0'

        other_data = data.select{|k,v| !['id','group'].include?(k) }
      elsif !decoded_jwt.empty?
        data = decoded_jwt
        id = data['user'] || 'unknown'
        group = data['group'] || 'unknown'
      else
        logger.warn("No X-Frontend header found for : #{request.url}")
      end

      from_cache = params['from_cache'] || '1'

      OpenStruct.new(from_cache: from_cache, query_user: id, query_group: group, other_data: other_data, language: params[:language] || solis_conf[:language] || 'nl')
    end

    def decoded_jwt()
      path = request.env['HTTP_X_FORWARDED_URI'] || ''
      parsed_path = CGI.parse(URI(path).query || '')

      token = if parsed_path.key?('apikey')
                  parsed_path['apikey'].first
              elsif params.key?('apikey')
                params['apikey']
              else
                request.env['HTTP_AUTHORIZATION']&.gsub(/^bearer /i, '') || nil
              end

      #token = parsed_path.key?('apikey') ? parsed_path['apikey'].first : request.env['HTTP_AUTHORIZATION']&.gsub(/^bearer /i, '') || nil

      if token && !token.blank? && !token.empty?
        JWT.decode(token, Solis::ConfigFile[:secret], true, {algorithm: 'HS512'}).first
      else
        {}
      end
    rescue StandardError => e
      LOGGER.warn('No JWT token defined')
      {}
    end

    def dump_by_content_type(resource, content_type)
      #raise "Content-Type: #{content_type} not found use one of\n #{RDF::Format.content_types.keys.join(', ')}" unless RDF::Format.content_types.key?(content_type)
      content_type_format = RDF::Format.for(:content_type   => content_type).to_sym
      #raise "No writer found for #{content_type}" if  RDF::Writer.for(content_type_format).nil?
      dump(resource, content_type_format)
    rescue StandardError => e
      dump(resource, :jsonapi)
    end

    def dump(resource, content_type_format)
      if RDF::Format.writer_symbols.include?(content_type_format)
        content_type RDF::Format.for(content_type_format).content_type.first
        resource.data.dump(content_type_format)
      else
        content_type :json
        resource.to_jsonapi
      end
    rescue StandardError => e
      content_type :json
      resource.to_jsonapi
    end

    def formats
      (['application/vnd.api+json', 'application/json'] | RDF::Format.content_types.keys)
    end
  end
  helpers MainHelper
end