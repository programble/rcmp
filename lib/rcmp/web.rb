require 'json'
require 'sinatra/base'

module RCMP
  class Web < Sinatra::Base
    def dispatch(params)
      begin
        payload = JSON.parse(params[:payload])
      rescue JSON::ParserError
        halt 400, 'invalid payload'
      end

      type = [GitHub, Travis, Bitbucket].find {|type| type.detect(payload) }
      halt 400, 'unknown payload type' unless type
      halt 403, 'unknown payload source' unless type.verify(request)

      params[:server] ||= 'default'
      server = Configru.irc.servers[params[:server]]
      server ||= Configru.irc.servers.find do |n, s|
        s['address'] == params[:server] ||
          s['alias'] == params[:server] ||
          s['alias'].include?(params[:server])
      end[1]
      halt 400, 'unknown server' unless server

      if params[:channel]
        channel = '#' + params[:channel]
        key = params[:key]
        nojoin, part, notice = %w[nojoin part notice].map do |flag|
          params.include? flag
        end
      else
        channel = server['channel']
        key = server['key']
        nojoin, part, notice = %w[nojoin part notice].map do |flag|
          params.include?(flag) ? true : server[flag]
        end
      end

      IRC[server].announce(channel, key, nojoin, part, notice, type.format(payload))
    end

    ['/:server/:channel', '/:channel', '/'].each do |route|
      post route do
        dispatch(params)
        'success'
      end
    end

    get '/' do
      'pong'
    end
  end
end
